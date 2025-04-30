exports.handler = async (event, context) => {
  if (event.httpMethod !== "PUT") {
    return {
      statusCode: 405,
      body: JSON.stringify({ message: "Method Not Allowed" }),
      headers: { "Content-Type": "application/json" },
    };
  }

  try {
    const { pageUrl, feedbackId, message } = JSON.parse(event.body);

    // Request to webhook goes here...
    console.log("Feedback update:");
    console.log(pageUrl);
    console.log(feedbackId);
    console.log(message);

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
};
