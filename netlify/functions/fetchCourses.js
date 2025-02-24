const { Client, fql } = require('fauna');

exports.handler = async () => {
    const client = new Client({
        secret: process.env.FAUNA_SECRET_KEY
    });

    try {
        const response = await client.query(fql`
            Courses.all().map(
                (doc) => {
                    let data = doc.data
                    {
                        id: doc.id,
                        title: data.title,
                        hidden: data.hidden,
                        subtitle: data.subtitle,
                        description: data.description,
                        content: data.content,
                        imageUrl: data.imageUrl,
                        price: data.price,
                        teachers: data.teachers,
                        periods: data.periods
                    }
                }
            )
        `);

        if (!response || !response.data) {
            throw new Error('Invalid response format from database');
        }

        console.log('FaunaDB Response:', response);

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET, OPTIONS'
            },
            body: JSON.stringify({
                data: response.data
            }),
        };
    } catch (error) {
        console.error('FaunaDB Error:', error);

        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET, OPTIONS'
            },
            body: JSON.stringify({
                error: 'Failed to fetch courses',
                details: error.message,
                type: error.constructor.name
            }),
        };
    }
};