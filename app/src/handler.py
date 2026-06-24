"""Hello World Lambda handler.

This is the deployable application. It is intentionally simple: it returns a
JSON payload that includes the environment name so you can visually confirm
which environment served the request.
"""

import json
import os


def handler(event, context):
    environment = os.environ.get("ENVIRONMENT", "unknown")
    app_name = os.environ.get("APP_NAME", "hello-app")
    version = os.environ.get("APP_VERSION", "0.0.0")

    body = {
        "message": "Hello World",
        "app": app_name,
        "environment": environment,
        "version": version,
    }

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }
