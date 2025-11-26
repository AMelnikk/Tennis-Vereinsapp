import dotenv from 'dotenv';
import sgMail from '@sendgrid/mail';

// .env laden
dotenv.config();

// API-Key setzen
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

const msg = {
  to: 'oliver@stroebel-home.de',
  from: 'oliver@stroebel-home.de', // verifizierte Adresse verwenden
  subject: 'Test Mail',
  text: 'Hallo, dies ist eine Testmail!'
};

// Mail senden
sgMail
.send(msg)
.then(() => {
console.log('✅ Test-Mail erfolgreich gesendet!');
})
.catch((error) => {
console.error('❌ Fehler beim Senden der Mail:', error.response?.body || error);
});