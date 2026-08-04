import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const ddb = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME || "respect-counter";
const COUNTER_ID = "rip-pierone";
const RATE_LIMIT_MS = 5000; // stesso cooldown di 5s del frontend, ma applicato per IP
const IP_RECORD_TTL_SECONDS = 3600; // le righe di rate-limit si auto-cancellano dopo 1h (TTL DynamoDB)

export const handler = async (event) => {
  const origin = event.headers?.origin || event.headers?.Origin || "";

  const corsHeaders = {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  };

  // Preflight CORS
  if (event.requestContext?.http?.method === "OPTIONS") {
    return { statusCode: 204, headers: corsHeaders, body: "" };
  }

  const method = event.requestContext?.http?.method;
  const sourceIp = event.requestContext?.http?.sourceIp || "unknown";

  try {
    if (method === "POST") {
      const now = Date.now();
      const ipKey = `ip#${sourceIp}`;

      // 1) Prova a "prenotare" l'IP per il rate-limit: riesce solo se
      //    non ha già cliccato negli ultimi RATE_LIMIT_MS millisecondi.
      //    Condizione atomica: evita race condition tra richieste concorrenti.
      try {
        await ddb.send(
          new UpdateCommand({
            TableName: TABLE_NAME,
            Key: { id: ipKey },
            UpdateExpression: "SET lastClick = :now, #ttl = :ttl",
            ConditionExpression:
              "attribute_not_exists(lastClick) OR lastClick < :threshold",
            ExpressionAttributeNames: { "#ttl": "ttl" },
            ExpressionAttributeValues: {
              ":now": now,
              ":threshold": now - RATE_LIMIT_MS,
              ":ttl": Math.floor(now / 1000) + IP_RECORD_TTL_SECONDS,
            },
          })
        );
      } catch (condErr) {
        if (condErr.name === "ConditionalCheckFailedException") {
          return {
            statusCode: 429,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
            body: JSON.stringify({
              error: "Troppo veloce, aspetta qualche secondo prima di riprovare.",
            }),
          };
        }
        throw condErr;
      }

      // 2) Rate-limit superato: incrementa il contatore globale
      const result = await ddb.send(
        new UpdateCommand({
          TableName: TABLE_NAME,
          Key: { id: COUNTER_ID },
          UpdateExpression: "ADD #cnt :inc",
          ExpressionAttributeNames: { "#cnt": "count" },
          ExpressionAttributeValues: { ":inc": 1 },
          ReturnValues: "UPDATED_NEW",
        })
      );
      return {
        statusCode: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        body: JSON.stringify({ count: result.Attributes.count }),
      };
    }

    if (method === "GET") {
      // Legge il contatore senza incrementarlo (ADD :0 non modifica il valore)
      const result = await ddb.send(
        new UpdateCommand({
          TableName: TABLE_NAME,
          Key: { id: COUNTER_ID },
          UpdateExpression: "ADD #cnt :zero",
          ExpressionAttributeNames: { "#cnt": "count" },
          ExpressionAttributeValues: { ":zero": 0 },
          ReturnValues: "UPDATED_NEW",
        })
      );
      return {
        statusCode: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
        body: JSON.stringify({ count: result.Attributes.count }),
      };
    }

    return { statusCode: 405, headers: corsHeaders, body: "Method Not Allowed" };
  } catch (err) {
    console.error(err);
    return {
      statusCode: 500,
      headers: corsHeaders,
      body: JSON.stringify({ error: "Internal error" }),
    };
  }
};
