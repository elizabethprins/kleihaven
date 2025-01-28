const { MailerSend, EmailParams, Sender, Recipient } = require('mailersend');

const mailerSend = new MailerSend({
    apiKey: process.env.MAILERSEND_API_KEY
});

async function sendConfirmationEmail({ email, name, numberOfSpots, course, periodId }) {
    const period = course.data.periods.find(p => p.id === periodId);

    try {
        const emailParams = new EmailParams()
            .setFrom(new Sender('kleihaven@trial-yzkq3406wxk4d796.mlsender.net', 'Kleihaven'))
            .setTo([new Recipient(email, name)])
            .setSubject('Bevestiging van je boeking bij Kleihaven')
            .setHtml(`<p>Beste ${name},</p>

<p>Bedankt voor je boeking bij Kleihaven! Je reservering is bevestigd.</p>

<h3>Details van je boeking:</h3>
<ul>
    <li>Cursus: ${course.data.title}</li>
    <li>Aantal plekken: ${numberOfSpots}</li>
    <li>Periode: ${period.startDate} t/m ${period.endDate}</li>
    <li>Tijden: ${period.timeInfo}</li>
</ul>

<p>We kijken ernaar uit je te verwelkomen!</p>

<p>Met vriendelijke groet,<br>
Team Kleihaven</p>`);

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