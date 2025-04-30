const { v4: uuidv4 } = require("uuid");

exports.handler = async (event, context) => {
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

    console.log("Feedback create:");
    console.log(pageUrl);
    console.log(feedbackId);
    console.log(vote);

    // Request to webhook goes here...
    if (feedbackId) {
      id = feedbackId;
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
};
