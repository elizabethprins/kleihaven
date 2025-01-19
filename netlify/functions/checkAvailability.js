const fauna = require('fauna');
const q = fauna.query;

exports.handler = async (event) => {
    if (event.httpMethod !== 'POST') {
        return { statusCode: 405, body: 'Method Not Allowed' };
    }

    const { courseId } = JSON.parse(event.body);
    const client = new fauna.Client({ secret: process.env.FAUNA_SECRET_KEY });

    try {
        const response = await client.query(
            q.Let(
                {
                    course: q.Get(q.Ref(q.Collection('Courses'), courseId)),
                },
                q.If(
                    q.GT(
                        q.Select(['data', 'availableSpots'], q.Var('course')),
                        0
                    ),
                    // Create temporary reservation
                    q.Update(q.Select('ref', q.Var('course')), {
                        data: {
                            availableSpots: q.Subtract(
                                q.Select(['data', 'availableSpots'], q.Var('course')),
                                1
                            ),
                            pendingReservations: q.Add(
                                q.Select(['data', 'pendingReservations'], q.Var('course'), 0),
                                1
                            )
                        }
                    }),
                    q.Abort('No spots available')
                )
            )
        );

        return {
            statusCode: 200,
            body: JSON.stringify({ success: true, reservation: response })
        };
    } catch (error) {
        return {
            statusCode: 400,
            body: JSON.stringify({ error: error.message })
        };
    }
}; 