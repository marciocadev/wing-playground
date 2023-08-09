bring cloud;
bring "./dynamodb-tf.w" as ddb;

class Person {
  table: ddb.DynamoDBTable;
  addPerson: cloud.Function;

  init() {
    this.table = new ddb.DynamoDBTable(
      partitionKey: ddb.KeyAttributeType {
        keyName: "name",
        type: ddb.AttributeType.String,
      },
      sortKey: ddb.KeyAttributeType {
        keyName: "surname",
        type: ddb.AttributeType.String,
      }
    ) as "Person";

    this.addPerson = new cloud.Function(inflight (event: str) => {
      log(event);
      this.table.putItem(event);
    }) as "addPerson";
  }
}

new Person();