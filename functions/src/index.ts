import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as sgMail from "@sendgrid/mail";
import * as admin from "firebase-admin";
const cors = require("cors");


admin.initializeApp();

const corsHandler = cors({ origin: true }); // erlaubt alle Domains, für Prod ggf. einschränken

export const sendMail = onRequest(
  { secrets: ["SENDGRID_KEY"] },
  async (req, res) => {
    corsHandler(req, res, async () => {
      logger.info("Starting email send...");

      try {
        const apiKey = process.env.SENDGRID_KEY;
        if (!apiKey) {
          throw new Error("SendGrid key missing");
        }

        sgMail.setApiKey(apiKey);

        const msg = {
          to: req.body.to,
          from: "oliver@stroebel-home.de", // MUSS bei SendGrid verifiziert sein!
          subject: req.body.subject,
          text: req.body.text,
        };

        await sgMail.send(msg);

        res.status(200).send({ success: true });
      } catch (error) {
        logger.error(error);
        const errMsg = error instanceof Error ? error.message : String(error);
        res.status(500).send({ error: errMsg });
      }
    });
  }
);