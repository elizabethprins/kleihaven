const { MailerSend, EmailParams, Sender, Recipient } = require('mailersend');

const mailerSend = new MailerSend({
    apiKey: process.env.MAILERSEND_API_KEY
});

async function sendConfirmationEmail({ email, name, numberOfSpots, course, periodId }) {
    const period = course.data.periods.find(p => p.id === periodId);
    const siteUrl = process.env.URL || 'http://localhost:3000';

    try {
        const emailParams = new EmailParams()
            .setFrom(new Sender('kleihaven@trial-yzkq3406wxk4d796.mlsender.net', 'Studio1931 // Kleihaven'))
            .setTo([new Recipient(email, name)])
            .setSubject('Bevestiging van je boeking bij Kleihaven')
            .setTemplateId('neqvygm5oqz40p7w')
            .setPersonalization([{
                email: email,
                data: {
                    name: name,
                    period: `${period.startDate} t/m ${period.endDate}`,
                    course_url: `${siteUrl}/cursussen?id=${course.data.id}`,
                    course_title: course.data.title,
                    numberOfSpots: numberOfSpots,
                    support_email: 'hello@studio1931.nl'
                }
            }]);

        await mailerSend.email.send(emailParams);
        console.log('Confirmation email sent to:', email);
        return true;
    } catch (error) {
        console.error('Failed to send confirmation email:', error);
        return false;
    }
}


exports.sendConfirmationEmail = sendConfirmationEmail;
exports.handler = async function (event, context) {
    if (event.httpMethod !== 'POST') {
        return {
            statusCode: 405,
            body: 'Method Not Allowed'
        };
    }

    const { email, name, numberOfSpots, course, periodId } = JSON.parse(event.body);

    const success = await sendConfirmationEmail({ email, name, numberOfSpots, course, periodId });

    return {
        statusCode: success ? 200 : 500,
        body: JSON.stringify({ success })
    };
};