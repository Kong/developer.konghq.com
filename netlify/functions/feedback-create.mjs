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

export default async function handler(request, context) {
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;
  let connection;

  if (!webhookUrl) {
    return new Response(
      JSON.stringify({ error: "Missing Slack webhook URL" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }

  if (request.method !== "POST") {
    return new Response(JSON.stringify({ message: "Method Not Allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  let id = uuidv4();

  try {
    const { pageUrl, vote } = await request.json();

    if (!pageUrl || typeof vote !== "boolean") {
      return new Response(JSON.stringify({ message: "Invalid input" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const url = new URL(pageUrl);
    url.hash = "";

    await sendDataToSlack(url, vote, id, webhookUrl);

    connection = createSnowflakeConnection();
    await connectSnowflake(connection);
    await createFeedbackInSnowflake(connection, id, url, vote, null);

    return new Response(
      JSON.stringify({
        message: "Feedback received",
        feedbackId: id,
        vote,
      }),
      { status: 201, headers: { "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error(error);
    return new Response(JSON.stringify({ message: "Server error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
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

export const config = {
  path: "/feedback/create",
  rateLimit: {
    windowLimit: 4,
    windowSize: 60,
    aggregateBy: ["ip", "domain"],
  },
};
