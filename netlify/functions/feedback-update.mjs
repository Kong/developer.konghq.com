export async function handler(event, context) {
  const webhookUrl = process.env.SLACK_WEBHOOK_URL;

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

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Feedback updated" }),
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
