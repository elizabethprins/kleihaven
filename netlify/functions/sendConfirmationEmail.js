const { MailerSend, EmailParams, Sender, Recipient } = require('mailersend');

const mailerSend = new MailerSend({
    apiKey: process.env.MAILERSEND_API_KEY
});

function formatDutchDate(isoDate) {
    const date = new Date(isoDate);

    const weekdays = {
        0: 'zo', 1: 'ma', 2: 'di', 3: 'wo', 4: 'do', 5: 'vr', 6: 'za'
    };

    const months = {
        0: 'januari', 1: 'februari', 2: 'maart', 3: 'april',
        4: 'mei', 5: 'juni', 6: 'juli', 7: 'augustus',
        8: 'september', 9: 'oktober', 10: 'november', 11: 'december'
    };

    const weekday = weekdays[date.getDay()];
    const day = date.getDate();
    const month = months[date.getMonth()];

    return `${weekday} ${day} ${month}`;
}

async function sendConfirmationEmail({ email, name, numberOfSpots, course, periodId, paymentId, paymentAmount, paymentCurrency }) {
    const period = course.data.periods.find(p => p.id === periodId);
    const siteUrl = process.env.URL || 'https://www.studio1931.nl';
    const ownerEmail = process.env.OWNER_EMAIL || 'hello@studio1931.nl';

    // Format dates in the same style as the Elm app
    const startDate = formatDutchDate(period.startDate);
    const endDate = formatDutchDate(period.endDate);

    // If dates are in same month, use shorter format for start date
    const sameMonth = new Date(period.startDate).getMonth() === new Date(period.endDate).getMonth();
    const periodString = sameMonth
        ? `${startDate.split(' ').slice(0, 2).join(' ')} t/m ${endDate}`
        : `${startDate} t/m ${endDate}`;

    try {
        const emailParams = new EmailParams()
            .setFrom(new Sender(ownerEmail, 'Studio1931 // Kleihaven'))
            .setTo([new Recipient(email, name)])
            .setSubject('Bevestiging van je boeking bij Kleihaven')
            .setTemplateId('neqvygm5oqz40p7w')
            .setPersonalization([{
                email: email,
                data: {
                    name: name,
                    period: periodString,
                    course_url: `${siteUrl}/cursussen?id=${course.data.id}`,
                    course_title: course.data.title,
                    numberOfSpots: numberOfSpots,
                    support_email: ownerEmail,
                    payment_amount: `${paymentCurrency} ${paymentAmount}`
                }
            }]);

        const ownerEmailParams = new EmailParams()
            .setFrom(new Sender(ownerEmail, 'Studio1931 // Kleihaven'))
            .setTo([new Recipient(ownerEmail, 'Studio1931')])
            .setSubject('Nieuwe boeking bij Kleihaven')
            .setTemplateId('7dnvo4d865rl5r86')
            .setPersonalization([{
                email: ownerEmail,
                data: {
                    customer_name: name,
                    customer_email: email,
                    period: periodString,
                    course_title: course.data.title,
                    numberOfSpots: numberOfSpots,
                    course_url: `${siteUrl}/cursussen?id=${course.data.id}`,
                    payment_id: paymentId,
                    payment_amount: `${paymentCurrency} ${paymentAmount}`
                }
            }]);

        await Promise.all([
            mailerSend.email.send(emailParams),
            mailerSend.email.send(ownerEmailParams)
        ]);
        console.log('Confirmation emails sent to:', email, 'and', ownerEmail);
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