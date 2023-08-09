const { DynamoDBClient, PutItemCommand, GetItemCommand } = require("@aws-sdk/client-dynamodb");
const { marshall, unmarshall } = require("@aws-sdk/util-dynamodb");

const client = new DynamoDBClient({});

export async function _putItem(tableName, item) {
  const command = new PutItemCommand({
    TableName: tableName,
    Item: marshall(item),
  });
  await client.send(command);
}

export async function _getItem(tableName, keys) {
  const command = new GetItemCommand({
    TableName: tableName,
    Key: marshall(keys),
  });
  const response = await client.send(command);
  console.log(JSON.stringify(response));
  return response.Item ? unmarshall(response.Item) : "Item not found";
}