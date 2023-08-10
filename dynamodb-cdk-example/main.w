bring cloud;
bring "./dynamodb-cdk.w" as ddb;

class Person {
  table: ddb.DynamoDBTable;
  addPerson: cloud.Function;
  // getPerson: cloud.Function;
  // deletePerson: cloud.Function;

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
      this.table.putItem(event);
    }) as "addPerson";

    // this.getPerson = new cloud.Function(inflight (event: str): Json => {
    //   return this.table.getItem(event);
    // }) as "getPerson";

    // this.deletePerson = new cloud.Function(inflight (event: str): Json => {
    //   return this.table.deleteItem(event);
    // }) as "deletePerson";
  }
}

new Person();