const { createMollieClient } = require('@mollie/api-client');

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, OPTIONS'
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

    if (event.httpMethod !== 'GET') {
        return {
            statusCode: 405,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'Method Not Allowed' })
        };
    }

    const paymentId = event.queryStringParameters.id;
    if (!paymentId) {
        return {
            statusCode: 400,
            headers: corsHeaders,
            body: JSON.stringify({ error: 'Payment ID is required' })
        };
    }

    const mollieClient = createMollieClient({ apiKey: process.env.MOLLIE_API_KEY });

    try {
        const payment = await mollieClient.payments.get(paymentId);

        return {
            statusCode: 200,
            headers: corsHeaders,
            body: JSON.stringify({
                status: payment.status,
                id: payment.id,
                amount: payment.amount,
                metadata: payment.metadata,
                description: payment.description
            })
        };
    } catch (error) {
        console.error('Payment status check failed:', error);
        return {
            statusCode: 500,
            headers: corsHeaders,
            body: JSON.stringify({ error: error.message })
        };
    }
}; 