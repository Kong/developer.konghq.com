import { v4 as uuidv4 } from "uuid";
import {
  createFeedbackInSnowflake,
  createSnowflakeConnection,
  connectSnowflake,
} from "../utils/snowflake.js";

async function sendDataToSlack(url, vote, id, webhookUrl) {
  const payload = {
    text: `New feedback received:\n• Page: ${url}\n• Vote: ${
      vote ? "Yes" : "No"
    }\n• Feedback Id: ${id}`,
  };

  const response = await fetch(webhookUrl, {
    method: "POST",
    body: JSON.stringify(payload),
    headers: { "Content-Type": "application/json" },
  });

  if (!response.ok) {
    throw new Error(`Slack API returned status ${response.status}`);
  }
}

export async function handler(event, context) {
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;
  let connection;

  if (!webhookUrl) {
    console.log("Missing Slack webhook URL.");
    return {
      statusCode: 500,
      body: JSON.stringify({ error: "Missing Slack webhook URL" }),
    };
  }

  if (event.httpMethod !== "POST") {
    return {
      statusCode: 405,
      body: JSON.stringify({ message: "Method Not Allowed" }),
      headers: { "Content-Type": "application/json" },
    };
  }

  let id = uuidv4();

  try {
    const { pageUrl, vote, feedbackId } = JSON.parse(event.body);

    if (!pageUrl || typeof vote !== "boolean") {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: "Invalid input" }),
        headers: { "Content-Type": "application/json" },
      };
    }

    if (feedbackId) {
      id = feedbackId;
    }

    const url = new URL(pageUrl);
    url.hash = "";

    await sendDataToSlack(url, vote, id, webhookUrl);

    connection = createSnowflakeConnection();
    await connectSnowflake(connection);

    await createFeedbackInSnowflake(connection, id, url, vote, null);

    return {
      statusCode: 201,
      body: JSON.stringify({
        message: "Feedback received",
        feedbackId: id,
        vote,
      }),
      headers: { "Content-Type": "application/json" },
    };
  } catch (error) {
    console.log(error.message);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Server error" }),
      headers: { "Content-Type": "application/json" },
    };
  } finally {
    if (connection) {
      connection.destroy((err) => {
        if (err) {
          console.error("Error disconnecting from Snowflake");
        }
      });
    }
  }
}
