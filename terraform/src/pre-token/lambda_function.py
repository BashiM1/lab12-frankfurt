import os
from typing import Any


RESOURCE_SERVER_IDENTIFIER = os.environ["RESOURCE_SERVER_IDENTIFIER"]

PYTHON_SCOPE = f"{RESOURCE_SERVER_IDENTIFIER}/python.invoke"
NODE_SCOPE = f"{RESOURCE_SERVER_IDENTIFIER}/node.invoke"
SECURITY_SCOPE = f"{RESOURCE_SERVER_IDENTIFIER}/security.read"

ALL_CUSTOM_SCOPES = {
    PYTHON_SCOPE,
    NODE_SCOPE,
    SECURITY_SCOPE,
}


def allowed_scopes(groups: set[str]) -> set[str]:
    scopes: set[str] = set()

    if "students" in groups:
        scopes.add(PYTHON_SCOPE)

    if "admins" in groups:
        scopes.update({PYTHON_SCOPE, NODE_SCOPE})

    if "security" in groups:
        scopes.update(ALL_CUSTOM_SCOPES)

    return scopes


def lambda_handler(event: dict[str, Any], context: Any) -> dict[str, Any]:
    group_configuration = (
        event.get("request", {})
        .get("groupConfiguration", {})
    )
    groups = set(
        group_configuration.get("groupsToOverride")
        or []
    )

    granted = allowed_scopes(groups)
    suppressed = ALL_CUSTOM_SCOPES - granted

    event["response"] = {
        "claimsAndScopeOverrideDetails": {
            "accessTokenGeneration": {
                "scopesToAdd": sorted(granted),
                "scopesToSuppress": sorted(suppressed),
            }
        }
    }

    return event

