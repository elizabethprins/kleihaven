const { Client, fql } = require('fauna');

exports.handler = async (event) => {
    // Only allow scheduled triggers
    if (!event.headers['x-trigger'] === 'SCHEDULED') {
        return {
            statusCode: 401,
            body: JSON.stringify({ error: 'Unauthorized' })
        };
    }

    const client = new Client({ secret: process.env.FAUNA_SECRET_KEY });

    // Set to true to test without making actual changes
    const isDryRun = event.queryStringParameters?.dryRun === 'true';

    try {
        // First get the current state
        const response = await client.query(fql`
            Courses.all().map(
                (doc) => {
                    let data = doc.data
                    {
                        id: doc.id,
                        title: data.title,
                        pendingReservations: data.periods.map(p => 
                            { 
                                id: p.id, 
                                pending: if (p.pendingReservations == null) 0 else p.pendingReservations 
                            }
                        )
                    }
                }
            )
        `);

        const currentState = response.data.data;
        console.log('Current pending reservations:', currentState);

        if (!isDryRun) {
            // Get all courses that need cleanup
            const coursesToClean = currentState.filter(course =>
                course.pendingReservations.some(p => p.pending > 0)
            );

            // Clean each course individually
            for (const course of coursesToClean) {
                const courseData = await client.query(fql`
                    Courses.byId(${course.id})
                `);

                const updatedPeriods = courseData.data.periods.map(p => ({
                    ...p,
                    pendingReservations: 0
                }));

                await client.query(fql`
                    Courses.byId(${course.id})
                    ?.update({ 
                        periods: ${updatedPeriods}
                    })
                `);
            }
        }

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: isDryRun ? 'Dry run completed' : 'Cleanup successful',
                wouldClean: currentState.filter(course =>
                    course.pendingReservations.some(p => p.pending > 0)
                )
            })
        };
    } catch (error) {
        console.error('Operation failed:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: error.message })
        };
    }
};

// Defines the schedule to run the function automatically
exports.config = {
    schedule: "@daily"  // Runs daily at midnight UTC
}; 