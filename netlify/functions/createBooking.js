const { createMollieClient } = require('@mollie/api-client');
const fauna = require('fauna');
const q = fauna.query;

exports.handler = async (event) => {
    if (event.httpMethod !== 'POST') {
        return { statusCode: 405, body: 'Method Not Allowed' };
    }

    const { courseId, periodId, email, name, numberOfSpots } = JSON.parse(event.body);
    const mollieClient = createMollieClient({ apiKey: process.env.MOLLIE_API_KEY });
    const client = new fauna.Client({ secret: process.env.FAUNA_SECRET_KEY });

    try {
        // Check availability in FaunaDB
        const course = await client.query(
            q.Get(q.Ref(q.Collection('Courses'), courseId))
        );

        const periods = q.Select('periods', course);
        const selectedPeriod = q.Get(q.Ref(q.Collection('Periods'), periodId));

        const totalSpots = q.Select('totalSpots', selectedPeriod);
        const bookedSpots = q.Select('bookedSpots', selectedPeriod);
        const pendingReservations = q.Select('pendingReservations', selectedPeriod);

        // Check if enough spots are available
        if (q.GT(q.Subtract(totalSpots, q.Add(bookedSpots, pendingReservations)), numberOfSpots)) {
            // Reserve the requested number of spots
            await client.query(
                q.Update(q.Select('ref', course), {
                    data: {
                        periods: q.Map(periods, period =>
                            q.If(
                                q.Equals(q.Select('id', period), q.Select('id', selectedPeriod)),
                                {
                                    ...period,
                                    bookedSpots: q.Add(bookedSpots, numberOfSpots)
                                },
                                period
                            )
                        )
                    }
                })
            );

            // Create a payment request with Mollie using the Mollie client
            const payment = await mollieClient.payments.create({
                amount: {
                    currency: 'EUR',
                    value: (course.data.price * numberOfSpots).toFixed(2)
                },
                description: `Reservation for ${course.data.title} (${numberOfSpots} spots)`,
                redirectUrl: `${process.env.URL}/booking/confirmation`,
                webhookUrl: `${process.env.URL}/.netlify/functions/handlePaymentWebhook`,
                metadata: {
                    courseId,
                    email,
                    name,
                    numberOfSpots
                }
            });

            return {
                statusCode: 200,
                body: JSON.stringify({ success: true, paymentUrl: payment.getCheckoutUrl() })
            };
        } else {
            return {
                statusCode: 400,
                body: JSON.stringify({ error: 'Not enough spots available' })
            };
        }
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
    }
}; 