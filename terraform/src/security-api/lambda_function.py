import json
import os
from datetime import datetime, timezone
from typing import Any

import boto3
from botocore.exceptions import ClientError


REQUIRED_GROUP = os.environ.get("REQUIRED_GROUP", "security")
TOKEN_TRACKING_TABLE = os.environ["TOKEN_TRACKING_TABLE"]

token_table = boto3.resource("dynamodb").Table(
    TOKEN_TRACKING_TABLE
)


def parse_groups(value: Any) -> set[str]:
    if isinstance(value, list):
        return {str(item).strip() for item in value if str(item).strip()}

    text = str(value or "").strip()
    if text.startswith("[") and text.endswith("]"):
        text = text[1:-1]

    return {
        item.strip().strip("\"'")
        for item in text.split(",")
        if item.strip()
    }


def mark_token_used(
    event: dict[str, Any],
    claims: dict[str, Any],
) -> bool:
    token_id = claims.get("jti")
    if not token_id:
        return False

    identity = event.get("requestContext", {}).get("identity", {})
    now = datetime.now(timezone.utc).isoformat()

    try:
        token_table.update_item(
            Key={"token_id": str(token_id)},
            UpdateExpression=(
                "SET used = :true, "
                "first_used_at = if_not_exists(first_used_at, :now), "
                "last_used_at = :now, "
                "token_status = :status, "
                "last_endpoint = :endpoint, "
                "source_ip = :source_ip, "
                "user_agent = :user_agent"
            ),
            ConditionExpression="attribute_exists(token_id)",
            ExpressionAttributeValues={
                ":true": True,
                ":now": now,
                ":status": "USED",
                ":endpoint": "/security/status",
                ":source_ip": identity.get("sourceIp", "not_collected"),
                ":user_agent": identity.get("userAgent", "not_collected")[:256],
            },
        )
        return True
    except ClientError as error:
        code = error.response.get("Error", {}).get("Code")
        if code == "ConditionalCheckFailedException":
            print(f"Token {token_id} was not registered in the tracking table.")
            return False
        raise


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    claims = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("claims", {})
        or {}
    )
    groups = parse_groups(claims.get("cognito:groups"))

    if REQUIRED_GROUP not in groups:
        status_code = 403
        body = {"error": "Access denied"}
    else:
        tracked = mark_token_used(event, claims)
        status_code = 200
        body = {
            "message": "Security scope validated.",
            "purpose": (
                "This endpoint is the authorization boundary for a future "
                "incident centre. It does not expose incident data."
            ),
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "username": claims.get("username"),
            "groups": sorted(groups),
            "scope": claims.get("scope", ""),
            "tracked_token_marked_used": tracked,
        }

    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }

