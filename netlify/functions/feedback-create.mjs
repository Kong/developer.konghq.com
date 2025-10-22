import { v4 as uuidv4 } from "uuid";
import {
  createFeedbackInSnowflake,
  createSnowflakeConnection,
  connectSnowflake,
} from "../utils/snowflake.js";
import { getDeployStore } from "@netlify/blobs";

const RATE_LIMIT_MS = 60 * 1_000;
const MAX_SUBMISSIONS = 4;

async function isRateLimited(ip, now, store) {
  const data = await store.get(ip, { type: "json" });
  const timestamps = data || [];

  const validTimestamps = timestamps.filter(
    (time) => now - time <= RATE_LIMIT_MS
  );

  if (validTimestamps.length === 0) {
    await store.delete(ip);
  } else {
    await store.setJSON(ip, validTimestamps);
  }
  return validTimestamps.length >= MAX_SUBMISSIONS;
}

async function addSubmission(ip, now, store) {
  const data = await store.get(ip, { type: "json" });

  const timestamps = data || [];
  timestamps.push(now);
  return await store.setJSON(ip, timestamps);
}

async function getOldestTimestamp(ip, store) {
  const data = await store.get(ip, { type: "json" });
  const timestamps = data || [];
  return timestamps.length > 0 ? Math.min(...timestamps) : null;
}

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
    const store = getDeployStore();

    const { pageUrl, vote } = await request.json();

    if (!pageUrl || typeof vote !== "boolean") {
      return new Response(JSON.stringify({ message: "Invalid input" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const now = Date.now();
    const clientIp = context.ip;

    if (await isRateLimited(clientIp, now, store)) {
      const oldestSubmission = await getOldestTimestamp(clientIp, store);
      const remaining = oldestSubmission
        ? Math.ceil((RATE_LIMIT_MS - (now - oldestSubmission)) / 1000)
        : 60;

      return new Response(
        JSON.stringify({
          error: `Rate limit exceeded. Try again in ${remaining} seconds.`,
        }),
        { status: 429, headers: { "Content-Type": "application/json" } }
      );
    }

    await addSubmission(clientIp, now, store);

    const url = new URL(pageUrl);
    url.hash = "";

    await sendDataToSlack(url, vote, id, webhookUrl);

    connection = createSnowflakeConnection();
    await connectSnowflake(connection);
    await createFeedbackInSnowflake(connection, id, url, vote, clientIp);

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
