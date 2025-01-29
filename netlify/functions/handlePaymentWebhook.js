const { createMollieClient } = require('@mollie/api-client');
const fauna = require('fauna');
const { fql } = fauna;
const { sendConfirmationEmail } = require('./sendConfirmationEmail');

async function removePendingReservation(client, payment) {
    try {
        const { metadata } = payment;
        const { courseId, periodId, numberOfSpots } = metadata;

        // Get current course data
        const course = await client.query(fql`
            Courses.byId(${courseId})
        `);

        if (!course || !course.data) {
            console.error('Course not found while removing pending reservation');
            return;
        }

        // Update the periods - only decrease pendingReservations
        const updatedPeriods = course.data.periods.map(p =>
            p.id === periodId
                ? {
                    ...p,
                    pendingReservations: Math.max(0, (p.pendingReservations || 0) - parseInt(numberOfSpots, 10))
                }
                : p
        );

        await client.query(fql`
            Courses.byId(${courseId})
            ?.update({
                periods: ${updatedPeriods}
            })
        `);

        console.log(`Removed pending reservation for course ${courseId}, period ${periodId}`);
    } catch (error) {
        console.error('Error removing pending reservation:', error);
    }
}

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
                periodId,
                paymentId: id,
                paymentAmount: payment.amount.value,
                paymentCurrency: payment.amount.currency
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
            // Remove pending reservation for failed payments
            await removePendingReservation(client, payment);
            return {
                statusCode: 400,
                body: JSON.stringify({ error: 'Payment not successful.' })
            };
        }
    } catch (error) {
        console.error('Webhook processing error:', error);

        // Try to remove pending reservation even if webhook processing failed
        try {
            const payment = await mollieClient.payments.get(id);
            await removePendingReservation(client, payment);
        } catch (e) {
            console.error('Failed to remove pending reservation after error:', e);
        }

        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
    }
}; 