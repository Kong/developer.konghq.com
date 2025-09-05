import snowflake from "snowflake-sdk";
import fs from "fs";
import path from "path";

snowflake.configure({
  logLevel: "ERROR",
});

export async function createFeedbackInSnowflake(
  connection,
  id,
  url,
  vote,
  body
) {
  const targetTableName = process.env.SNOWFLAKE_TARGET_TABLE;
  if (!targetTableName) {
    throw new Error("Missing SNOWFLAKE_TARGET_TABLE environment variable.");
  }

  const sentiment = vote ? "positive" : "negative";

  const statementResult = await new Promise((resolve, reject) => {
    connection.execute({
      sqlText: `INSERT INTO ${targetTableName} (id, url, sentiment, body, timestamp) VALUES (?, ?, ?, ?, ?)`,
      binds: [id, url.href, sentiment, body, new Date().toISOString()],
      complete: (err) => {
        if (err) {
          console.error("Failed to create feedback " + err.message);
          return reject(err);
        }
        resolve();
      },
    });
  });

  return statementResult;
}

export async function updateFeedbackInSnowflake(connection, id, body) {
  const targetTableName = process.env.SNOWFLAKE_TARGET_TABLE;
  if (!targetTableName) {
    throw new Error("Missing SNOWFLAKE_TARGET_TABLE environment variable.");
  }
  const statementResult = await new Promise((resolve, reject) => {
    connection.execute({
      sqlText: `UPDATE ${targetTableName} SET body = ?, timestamp = ? WHERE id = ? `,
      binds: [body, new Date().toISOString(), id],
      complete: (err, stmt, rows) => {
        if (err) {
          console.error("Failed to update feedback " + err.message);
          return reject(err);
        }
        resolve({ rowsAffected: rows });
      },
    });
  });

  if (statementResult.rowsAffected === 0) {
    throw new Error(`Failed to update feedback: No row found with ID '${id}'`);
  }

  return statementResult;
}

function checkRequiredEnv(vars) {
  const missing = vars.filter((key) => !process.env[key]);
  if (missing.length) {
    throw new Error(`Missing env vars: ${missing.join(", ")}`);
  }
}

export function createSnowflakeConnection() {
  checkRequiredEnv([
    "SNOWFLAKE_USER",
    "SNOWFLAKE_ACCOUNT",
    "SNOWFLAKE_PRIVATE_KEY",
    "SNOWFLAKE_WAREHOUSE",
    "SNOWFLAKE_DATABASE",
    "SNOWFLAKE_SCHEMA",
    "SNOWFLAKE_ROLE",
  ]);

  const user = process.env.SNOWFLAKE_USER;
  const account = process.env.SNOWFLAKE_ACCOUNT;
  const warehouse = process.env.SNOWFLAKE_WAREHOUSE;
  const database = process.env.SNOWFLAKE_DATABASE;
  const schema = process.env.SNOWFLAKE_SCHEMA;
  const role = process.env.SNOWFLAKE_ROLE;
  const privateKey = Buffer.from(
    process.env.SNOWFLAKE_PRIVATE_KEY,
    "base64"
  ).toString("utf8");

  return snowflake.createConnection({
    account: account,
    username: user,
    authenticator: "SNOWFLAKE_JWT",
    privateKey: privateKey,
    warehouse: warehouse,
    database: database,
    schema: schema,
    role: role,
  });
}

export async function connectSnowflake(connection) {
  return new Promise((resolve, reject) => {
    connection.connect(function (err) {
      if (err) {
        console.error("Unable to connect to Snowflake: " + err.message);
        return reject(err);
      }
      resolve();
    });
  });
}
