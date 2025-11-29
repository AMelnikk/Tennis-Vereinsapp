import * as functions from "firebase-functions";
import sgMail from "@sendgrid/mail";

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

export const sendEmail = functions.https.onCall(async (data, context) => {
  const to = data.to;
  const subject = data.subject;
  const text = data.text;

  if (!to || !subject || !text) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Empfänger, Betreff oder Text fehlen"
    );
  }

  try {
    await sgMail.send({
      to,
      from: "oliver@stroebel-home.de", // deine Absender-Adresse
      subject,
      text,
    });
    return { success: true, message: "Mail gesendet!" };
  } catch (error) {
    console.error(error);
    throw new functions.https.HttpsError("internal", error.message, error);
  }
});

export const testSendKey = functions.https.onCall(async () => {
  try {
    const msg = {
      to: "deineEmail@domain.de",
      from: "oliver@stroebel-home.de",
      subject: "Test SendGrid Key",
      text: "Wenn du diese Mail bekommst, funktioniert der Key.",
    };
    await sgMail.send(msg);
    return { success: true };
  } catch (e) {
    return { success: false, error: e.message };
  }
});