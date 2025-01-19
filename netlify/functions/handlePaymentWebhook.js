const { createMollieClient } = require('@mollie/api-client');
const fauna = require('fauna');
const q = fauna.query;

exports.handler = async (event) => {
    if (event.httpMethod !== 'POST') {
        return { statusCode: 405, body: 'Method Not Allowed' };
    }

    const { id } = event.body;
    const mollieClient = createMollieClient({ apiKey: process.env.MOLLIE_API_KEY });
    const client = new fauna.Client({ secret: process.env.FAUNA_SECRET_KEY });

    try {
        const payment = await mollieClient.payments.get(id);

        if (payment.isPaid()) {
            // Create booking in FaunaDB
            await client.query(
                q.Create(q.Collection('Bookings'), {
                    data: {
                        courseId: payment.metadata.courseId,
                        email: payment.metadata.email,
                        name: payment.metadata.name,
                        paymentId: payment.id,
                        status: 'confirmed'
                    }
                })
            );
        }

        return {
            statusCode: 200,
            body: 'Webhook processed'
        };
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
    }
}; 