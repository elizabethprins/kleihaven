const { createMollieClient } = require('@mollie/api-client');
const fauna = require('fauna');
const { fql } = fauna;
const { sendConfirmationEmail } = require('./sendConfirmationEmail');

exports.handler = async (event) => {
    console.log('Webhook received:', {
        body: event.body,
        headers: event.headers,
        method: event.httpMethod
    });

    if (event.httpMethod !== 'POST') {
        return { statusCode: 405, body: 'Method Not Allowed' };
    }

    let id;
    try {
        // Try parsing as JSON first
        const data = JSON.parse(event.body);
        id = data.id;
    } catch (e) {
        // If JSON parsing fails, try URL-encoded format
        const params = new URLSearchParams(event.body);
        id = params.get('id');
    }

    if (!id) {
        console.error('No payment ID found in webhook payload');
        return {
            statusCode: 400,
            body: JSON.stringify({ error: 'No payment ID provided' })
        };
    }

    const mollieClient = createMollieClient({ apiKey: process.env.MOLLIE_API_KEY });
    const client = new fauna.Client({ secret: process.env.FAUNA_SECRET_KEY });

    try {
        // Retrieve the payment status from Mollie
        const payment = await mollieClient.payments.get(id);

        if (payment.status === 'paid') {
            // Payment is successful, update the booking in FaunaDB
            const { metadata } = payment;
            const { courseId, periodId, email, name } = metadata;
            const numberOfSpots = parseInt(metadata.numberOfSpots, 10);

            // Get current course data
            const course = await client.query(fql`
                Courses.byId(${courseId})
            `);

            if (!course || !course.data) {
                return {
                    statusCode: 404,
                    body: JSON.stringify({ error: 'Course not found' })
                };
            }

            // Update the periods
            const updatedPeriods = course.data.periods.map(p =>
                p.id === periodId
                    ? {
                        ...p,
                        bookedSpots: (p.bookedSpots || 0) + numberOfSpots,
                        pendingReservations: Math.max(0, (p.pendingReservations || 0) - numberOfSpots)
                    }
                    : p
            );

            await client.query(fql`
                Courses.byId(${courseId})
                ?.update({
                    periods: ${updatedPeriods}
                })
            `);

            // Send confirmation email
            const emailSent = await sendConfirmationEmail({
                email,
                name,
                numberOfSpots,
                course,
                periodId
            });

            if (!emailSent) {
                console.warn('Booking confirmed but email failed to send');
            }

            return {
                statusCode: 200,
                body: JSON.stringify({
                    success: true,
                    message: 'Payment processed and booking confirmed.'
                })
            };
        } else {
            return {
                statusCode: 400,
                body: JSON.stringify({ error: 'Payment not successful.' })
            };
        }
    } catch (error) {
        console.error('Webhook processing error:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
    }
}; 