const { createMollieClient } = require('@mollie/api-client');
const fauna = require('fauna');
const q = fauna.query;

exports.handler = async (event) => {
    if (event.httpMethod !== 'POST') {
        return { statusCode: 405, body: 'Method Not Allowed' };
    }

    const { id } = JSON.parse(event.body); // Get the payment ID from the webhook
    const mollieClient = createMollieClient({ apiKey: process.env.MOLLIE_API_KEY });
    const client = new fauna.Client({ secret: process.env.FAUNA_SECRET_KEY });

    try {
        // Retrieve the payment status from Mollie
        const payment = await mollieClient.payments.get(id);

        if (payment.isPaid()) {
            // Payment is successful, update the booking in FaunaDB
            const { metadata } = payment; // Get metadata which includes courseId, periodId, etc.
            const { courseId, periodId, email, name, numberOfSpots } = metadata;

            // Update the corresponding period in FaunaDB
            const course = await client.query(
                q.Get(q.Ref(q.Collection('Courses'), courseId))
            );

            const periods = q.Select('periods', course);
            const selectedPeriod = q.Get(q.Ref(q.Collection('Periods'), periodId));

            // Update booked spots for the selected period
            await client.query(
                q.Update(q.Select('ref', course), {
                    data: {
                        periods: q.Map(periods, period =>
                            q.If(
                                q.Equals(q.Select('id', period), q.Select('id', selectedPeriod)),
                                {
                                    ...period,
                                    bookedSpots: q.Add(q.Select('bookedSpots', period), numberOfSpots) // Update booked spots
                                },
                                period
                            )
                        )
                    }
                })
            );

            return {
                statusCode: 200,
                body: JSON.stringify({ success: true, message: 'Payment processed and booking confirmed.' })
            };
        } else {
            return {
                statusCode: 400,
                body: JSON.stringify({ error: 'Payment not successful.' })
            };
        }
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
    }
}; 