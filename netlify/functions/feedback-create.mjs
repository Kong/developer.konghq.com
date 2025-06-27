import { v4 as uuidv4 } from "uuid";

export async function handler(event, context) {
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;

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
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Server error", error: error.message }),
      headers: { "Content-Type": "application/json" },
    };
  }
}
