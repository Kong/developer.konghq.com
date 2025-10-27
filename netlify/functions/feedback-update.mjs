import {
  updateFeedbackInSnowflake,
  createSnowflakeConnection,
  connectSnowflake,
} from "../utils/snowflake";

export default async (req, context) => {
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;
  let connection;

  if (req.method !== "PUT") {
    return new Response(JSON.stringify({ message: "Method Not Allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { pageUrl, feedbackId, message } = await req.json();

    const url = new URL(pageUrl);
    url.hash = "";

    const payload = {
      text: `Update feedback received:\n• Page: ${url}\n• Feedback Id: ${feedbackId}\n• Message: ${message}`,
    };

    await fetch(webhookUrl, {
      method: "POST",
      body: JSON.stringify(payload),
      headers: { "Content-Type": "application/json" },
    });

    connection = createSnowflakeConnection();
    await connectSnowflake(connection);

    await updateFeedbackInSnowflake(connection, feedbackId, message);

    return new Response(JSON.stringify({ message: "Feedback updated" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.log(error.message);
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
};

export const config = {
  path: "/feedback/update",
  method: "PUT",
  rateLimit: {
    windowLimit: 4,
    windowSize: 60,
    aggregateBy: ["ip", "domain"],
  },
};
