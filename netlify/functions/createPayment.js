const { createMollieClient } = require('@mollie/api-client');
const fauna = require('fauna');
const q = fauna.query;

exports.handler = async (event) => {
    if (event.httpMethod !== 'POST') {
        return { statusCode: 405, body: 'Method Not Allowed' };
    }

    const { courseId, email, name } = JSON.parse(event.body);
    const mollieClient = createMollieClient({ apiKey: process.env.MOLLIE_API_KEY });
    const client = new fauna.Client({ secret: process.env.FAUNA_SECRET_KEY });

    try {
        const course = await client.query(
            q.Get(q.Ref(q.Collection('Courses'), courseId))
        );

        const payment = await mollieClient.payments.create({
            amount: {
                currency: 'EUR',
                value: course.data.price.toFixed(2)
            },
            description: `Booking for ${course.data.title}`,
            redirectUrl: `${process.env.URL}/booking/confirmation`,
            webhookUrl: `${process.env.URL}/.netlify/functions/handlePaymentWebhook`,
            metadata: {
                courseId,
                email,
                name
            }
        });

        return {
            statusCode: 200,
            body: JSON.stringify({
                checkoutUrl: payment.getCheckoutUrl()
            })
        };
    } catch (error) {
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
    }
}; 