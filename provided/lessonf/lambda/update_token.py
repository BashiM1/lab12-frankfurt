table.update_item(
    Key={"token_id": token_id},
    UpdateExpression="SET used = :u",
    ExpressionAttributeValues={
        ":u": True
    }
)
