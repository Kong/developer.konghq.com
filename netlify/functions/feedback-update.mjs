import {
  updateFeedbackInSnowflake,
  createSnowflakeConnection,
  connectSnowflake,
} from "../utils/snowflake";

export async function handler(event, context) {
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;
  let connection;

  if (event.httpMethod !== "PUT") {
    return {
      statusCode: 405,
      body: JSON.stringify({ message: "Method Not Allowed" }),
      headers: { "Content-Type": "application/json" },
    };
  }

  try {
    const { pageUrl, feedbackId, message } = JSON.parse(event.body);

    const url = new URL(pageUrl);
    url.hash = "";

    const payload = {
      text: `Update feedback received:\n• Page: ${url}\n• Feedback Id: ${feedbackId}\n• Message: ${message}`,
    };

    const response = await fetch(webhookUrl, {
      method: "POST",
      body: JSON.stringify(payload),
      headers: { "Content-Type": "application/json" },
    });

    connection = createSnowflakeConnection();
    await connectSnowflake(connection);

    await updateFeedbackInSnowflake(connection, feedbackId, message);

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Feedback updated" }),
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
