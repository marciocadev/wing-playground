const { DynamoDBClient, PutItemCommand } = require("@aws-sdk/client-dynamodb");
const { marshall } = require("@aws-sdk/util-dynamodb");

const client = new DynamoDBClient({});

export async function _putItem(tableName, item) {
  const command = new PutItemCommand({
    TableName: tableName,
    Item: marshall(item),
  });
  await client.send(command);
}
