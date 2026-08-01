"use strict";

const {
    DynamoDBClient,
    UpdateItemCommand,
} = require("@aws-sdk/client-dynamodb");

const dynamodb = new DynamoDBClient({});
const tableName = process.env.TOKEN_TRACKING_TABLE;
const requiredGroups = new Set(
    (process.env.REQUIRED_GROUPS || "admins,security")
        .split(",")
        .map((value) => value.trim())
        .filter(Boolean)
);

function parseGroups(value) {
    if (Array.isArray(value)) {
        return new Set(value.map(String));
    }

    const text = String(value || "").trim();
    if (!text) {
        return new Set();
    }

    const normalized =
        text.startsWith("[") && text.endsWith("]")
            ? text.slice(1, -1)
            : text;

    return new Set(
        normalized
            .split(",")
            .map((item) => item.trim().replace(/^['"]|['"]$/g, ""))
            .filter(Boolean)
    );
}

function jsonResponse(statusCode, body) {
    return {
        statusCode,
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify(body),
    };
}

async function markTokenUsed(event, claims) {
    const tokenId = claims.jti;
    if (!tokenId) {
        console.log("Access token did not contain a jti claim.");
        return false;
    }

    const identity = event.requestContext?.identity || {};
    const now = new Date().toISOString();

    try {
        await dynamodb.send(
            new UpdateItemCommand({
                TableName: tableName,
                Key: {token_id: {S: String(tokenId)}},
                UpdateExpression:
                    "SET used = :true, " +
                    "first_used_at = if_not_exists(first_used_at, :now), " +
                    "last_used_at = :now, " +
                    "token_status = :status, " +
                    "last_endpoint = :endpoint, " +
                    "source_ip = :source_ip, " +
                    "user_agent = :user_agent",
                ConditionExpression: "attribute_exists(token_id)",
                ExpressionAttributeValues: {
                    ":true": {BOOL: true},
                    ":now": {S: now},
                    ":status": {S: "USED"},
                    ":endpoint": {S: "/node"},
                    ":source_ip": {
                        S: String(identity.sourceIp || "not_collected"),
                    },
                    ":user_agent": {
                        S: String(identity.userAgent || "not_collected").slice(0, 256),
                    },
                },
            })
        );
        return true;
    } catch (error) {
        if (error.name === "ConditionalCheckFailedException") {
            console.log(
                `Token ${tokenId} was valid but was not registered in the tracking table.`
            );
            return false;
        }
        throw error;
    }
}

exports.handler = async (event) => {
    const claims = event.requestContext?.authorizer?.claims || {};
    const groups = parseGroups(claims["cognito:groups"]);
    const authorized = [...groups].some((group) => requiredGroups.has(group));

    if (!authorized) {
        return jsonResponse(403, {error: "Access denied"});
    }

    const tracked = await markTokenUsed(event, claims);
    const name = event.queryStringParameters?.name || "Engineer";

    return jsonResponse(200, {
        message: `Hello ${String(name).toUpperCase()} from Node.js.`,
        username: claims.username,
        groups: [...groups].sort(),
        scope: claims.scope || "",
        tracked_token_marked_used: tracked,
    });
};

