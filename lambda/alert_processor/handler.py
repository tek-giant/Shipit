import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def summarise(message: str) -> str:
    """Turn an SNS message body into one readable line."""
    try:
        data = json.loads(message)
    except json.JSONDecodeError:
        return f"TEXT message: {message[:200]}"

    if isinstance(data, dict) and "AlarmName" in data:
        reason = str(data.get("NewStateReason", ""))[:200]
        return (
            f"ALARM {data['AlarmName']}: "
            f"{data.get('OldStateValue')} -> {data.get('NewStateValue')} | {reason}"
        )
    return f"JSON message: {json.dumps(data)[:200]}"


def handler(event, context):
    records = event.get("Records", [])
    for record in records:
        logger.info(summarise(record["Sns"]["Message"]))
    return {"processed": len(records)}
