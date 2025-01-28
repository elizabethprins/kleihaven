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
                body: JSON.stringify({
                    error: 'PERIOD_NOT_FOUND',
                    message: 'De gekozen cursusperiode bestaat niet meer.'
                })
            };
        }

        // Check availability
        const availableSpots = period.totalSpots - (period.bookedSpots + (period.pendingReservations || 0));

        if (availableSpots < numberOfSpots) {
            return {
                statusCode: 400,
                headers: corsHeaders,
                body: JSON.stringify({
                    error: 'SPOTS_NOT_AVAILABLE',
                    message: 'Er zijn niet genoeg plekken meer beschikbaar.'
                })
            };
        } else {
            const siteUrl = process.env.URL || 'http://localhost:3000';
            const isDevelopment = !process.env.URL;

            // Create payment request with Mollie
            const paymentData = {
                amount: {
                    currency: 'EUR',
                    value: (parseFloat(data.price) * numberOfSpots).toFixed(2)
                },
                description: `Boeking voor ${data.title} (${numberOfSpots} plekken)`,
                redirectUrl: `${siteUrl}/boeking/bevestiging`,
                metadata: {
                    courseId,
                    periodId,
                    email,
                    name,
                    numberOfSpots
                }
            };

            // Only add webhook URL in production
            if (!isDevelopment) {
                paymentData.webhookUrl = `${siteUrl}/.netlify/functions/handlePaymentWebhook`;
            }

            const payment = await mollieClient.payments.create(paymentData);

            // Update the redirect URL with the payment ID
            await mollieClient.payments.update(payment.id, {
                redirectUrl: `${siteUrl}/boeking/bevestiging?id=${payment.id}`
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
        console.error('Booking creation failed:', error);

        // Handle specific error cases
        if (error.name === 'NotFound') {
            return {
                statusCode: 404,
                headers: corsHeaders,
                body: JSON.stringify({
                    error: 'PERIOD_NOT_FOUND',
                    message: 'De gekozen cursusperiode bestaat niet meer.'
                })
            };
        }

        if (error.message?.includes('The redirect URL is invalid')) {
            return {
                statusCode: 400,
                headers: corsHeaders,
                body: JSON.stringify({
                    error: 'PAYMENT_CONFIG_ERROR',
                    message: 'Er is een probleem met de betalingsconfiguratie. Probeer het later opnieuw.'
                })
            };
        }

        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({
                error: 'UNKNOWN_ERROR',
                message: 'Er is iets misgegaan. Probeer het later opnieuw.'
            })
        };
    }
}; 