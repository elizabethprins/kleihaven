const { createMollieClient } = require('@mollie/api-client');
const fauna = require('fauna');
const { fql } = fauna;
const sendConfirmationEmail = require('./sendConfirmationEmail');

exports.handler = async (event) => {
    if (event.httpMethod !== 'POST') {
        return { statusCode: 405, body: 'Method Not Allowed' };
    }

    const { id } = JSON.parse(event.body);
    const mollieClient = createMollieClient({ apiKey: process.env.MOLLIE_API_KEY });
    const client = new fauna.Client({ secret: process.env.FAUNA_SECRET_KEY });

    try {
        // Retrieve the payment status from Mollie
        const payment = await mollieClient.payments.get(id);

        if (payment.isPaid()) {
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