const { Client, fql } = require('fauna');
const { createMollieClient } = require('@mollie/api-client');

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS'
};

exports.handler = async (event) => {
    // Handle CORS preflight requests
    if (event.httpMethod === 'OPTIONS') {
        return {
            statusCode: 200,
            headers: corsHeaders,
            body: ''
        };
    }

    if (event.httpMethod !== 'POST') {
        return {
            statusCode: 405,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'Method Not Allowed' })
        };
    }

    const { courseId, periodId, email, name, numberOfSpots } = JSON.parse(event.body);
    const mollieClient = createMollieClient({ apiKey: process.env.MOLLIE_API_KEY });
    const client = new Client({ secret: process.env.FAUNA_SECRET_KEY });

    try {
        // Find the course
        const course = await client.query(fql`
            Courses.byId(${courseId})
        `);

        const data = {
            id: course.data.id,
            title: course.data.title,
            description: course.data.description,
            imageUrl: course.data.imageUrl,
            price: course.data.price,
            periods: course.data.periods
        }

        // Find the requested period
        const period = data.periods.find(p => p.id === periodId);
        if (!period) {
            return {
                statusCode: 404,
                headers: corsHeaders,
                body: JSON.stringify({ error: 'Period not found' })
            };
        }

        // Check availability
        const availableSpots = period.totalSpots - (period.bookedSpots + (period.pendingReservations || 0));

        if (availableSpots < numberOfSpots) {
            return {
                statusCode: 400,
                headers: corsHeaders,
                body: JSON.stringify({ error: 'Not enough spots available' })
            };
        } else {
            // Create payment request with Mollie
            const payment = await mollieClient.payments.create({
                amount: {
                    currency: 'EUR',
                    value: (parseFloat(data.price) * numberOfSpots).toFixed(2)
                },
                description: `Boeking voor ${data.title} (${numberOfSpots} plekken)`,
                redirectUrl: `${process.env.URL}/booking/confirmation`,
                webhookUrl: `${process.env.URL}/.netlify/functions/handlePaymentWebhook`,
                metadata: {
                    courseId,
                    periodId,
                    email,
                    name,
                    numberOfSpots
                }
            });

            // Update pending reservations
            const updatedPeriods = data.periods.map(p =>
                p.id === periodId
                    ? { ...p, pendingReservations: (p.pendingReservations || 0) + numberOfSpots }
                    : p
            );
            await client.query(fql`
                Courses.byId(${courseId})
                ?.update({
                    periods: ${updatedPeriods}
                })
            `);

            return {
                statusCode: 200,
                headers: corsHeaders,
                body: JSON.stringify({
                    success: true,
                    paymentUrl: payment.getCheckoutUrl()
                })
            };
        }
    } catch (error) {
        console.error('Booking creation failed:', {
            error: error.message,
            stack: error.stack,
            body: event.body,
            name: error.name,
            message: error.message
        });
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({
                error: error.message,
                code: error.code,
            })
        };
    }
}; 