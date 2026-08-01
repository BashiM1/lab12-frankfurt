import json
import os
from datetime import datetime, timezone
from typing import Any

import boto3
from botocore.exceptions import ClientError


TOKEN_TRACKING_TABLE = os.environ["TOKEN_TRACKING_TABLE"]
REQUIRED_GROUPS = {
    value.strip()
    for value in os.environ.get(
        "REQUIRED_GROUPS",
        "students,admins,security",
    ).split(",")
    if value.strip()
}

token_table = boto3.resource("dynamodb").Table(
    TOKEN_TRACKING_TABLE
)


def parse_groups(value: Any) -> set[str]:
    if isinstance(value, list):
        return {str(item).strip() for item in value if str(item).strip()}

    text = str(value or "").strip()
    if not text:
        return set()

    if text.startswith("[") and text.endswith("]"):
        text = text[1:-1]

    return {
        item.strip().strip("\"'")
        for item in text.split(",")
        if item.strip()
    }


def request_claims(event: dict[str, Any]) -> dict[str, Any]:
    return (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("claims", {})
        or {}
    )


def mark_token_used(
    event: dict[str, Any],
    claims: dict[str, Any],
    endpoint: str,
) -> bool:
    token_id = claims.get("jti")
    if not token_id:
        print("Access token did not contain a jti claim.")
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
                ":endpoint": endpoint,
                ":source_ip": identity.get("sourceIp", "not_collected"),
                ":user_agent": identity.get("userAgent", "not_collected")[:256],
            },
        )
        return True

    except ClientError as error:
        code = error.response.get("Error", {}).get("Code")
        if code == "ConditionalCheckFailedException":
            print(f"Token {token_id} was valid but was not registered in the tracking table.")
            return False
        raise


def response(status_code: int, body: dict[str, Any]) -> dict[str, Any]:
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    claims = request_claims(event)
    groups = parse_groups(claims.get("cognito:groups"))

    if not groups.intersection(REQUIRED_GROUPS):
        return response(403, {"error": "Access denied"})

    tracked = mark_token_used(event, claims, "/python")
    name = (
        event.get("queryStringParameters") or {}
    ).get("name", "Engineer")

    return response(
        200,
        {
            "message": f"Hello {name} from Python.",
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "username": claims.get("username"),
            "groups": sorted(groups),
            "scope": claims.get("scope", ""),
            "tracked_token_marked_used": tracked,
        },
    )

