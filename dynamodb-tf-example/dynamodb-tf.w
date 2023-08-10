bring cloud;
bring "@cdktf/provider-aws" as tfaws;
bring aws;
bring util;

enum AttributeType {
  String,
  Number,
  Binary,
}

struct Attribute {
  value: Json;
  type: AttributeType;
}

struct KeyAttributeType {
  keyName: str;
  type: AttributeType;
}

struct DynamoDBTableProps {
    partitionKey: KeyAttributeType;
    sortKey: KeyAttributeType?;
}

class DynamoDBTable {
  table: tfaws.dynamodbTable.DynamodbTable;
  tableName: str;
  partitionKeyName: str;
  sortKeyName: str?;

  init(props: DynamoDBTableProps) {
    let target = util.env("WING_TARGET");
    if target != "tf-aws" {
      throw("Unsupported target: ${target} (expected: 'tf-aws')");
    }

    this.partitionKeyName = props.partitionKey.keyName;
    this.sortKeyName = props.sortKey?.keyName;
    let attributeList: MutArray<Map<str>> = MutArray<Map<str>>[
      Map<str> {
        "name" => props.partitionKey.keyName,
        "type" => this._keyAttributeTypeToString(props.partitionKey.type),
      }
    ];
    if let sortKey = props.sortKey {
      attributeList.push(Map<str> {
        "name" => sortKey.keyName,
        "type" => this._keyAttributeTypeToString(sortKey.type),
      });
    }

    this.table = new tfaws.dynamodbTable.DynamodbTable(
      name: "${this.node.id}-${this.node.addr.substring(this.node.addr.length -8)}",
      attribute: attributeList,
      billingMode: "PAY_PER_REQUEST",
      hashKey: this.partitionKeyName,
      rangeKey: this.sortKeyName,
    );
    this.tableName = this.table.name;
  }

  _bind(host: std.IInflightHost, ops: Array<str>) {
    if let host = aws.Function.from(host) {
      if ops.contains("putItem") {
        host.addPolicyStatements([
          aws.PolicyStatement {
            actions: ["dynamodb:PutItem"],
            effect: aws.Effect.ALLOW,
            resources: [this.table.arn],
          }
        ]);
      }

      if ops.contains("updateItem") {
        host.addPolicyStatements([
          aws.PolicyStatement {
            actions: ["dynamodb:UpdateItem"],
            effect: aws.Effect.ALLOW,
            resources: [this.table.arn],
          }
        ]);
      }

      if ops.contains("deleteItem") {
        host.addPolicyStatements([
          aws.PolicyStatement {
            actions: ["dynamodb:DeleteItem"],
            effect: aws.Effect.ALLOW,
            resources: [this.table.arn],
          }
        ]);
      }

      if ops.contains("getItem") {
        host.addPolicyStatements([
          aws.PolicyStatement {
            actions: ["dynamodb:GetItem"],
            effect: aws.Effect.ALLOW,
            resources: [this.table.arn],
          }
        ]);
      }
    }
  }

  extern "./dynamodb.js" inflight _putItem(tableName: str, item: Json): void;
  inflight putItem(item: Json): void {
    this._putItem(this.tableName, item);
  }

  extern "./dynamodb.js" inflight _getItem(tableName: str, item: Json): Json;
  inflight getItem(item: Json): Json {
    return this._getItem(this.tableName, item);
  }

  extern "./dynamodb.js" inflight _deleteItem(tableName: str, item: Json): Json;
  inflight deleteItem(item: Json): Json {
    return this._deleteItem(this.tableName, item);
  }

  _keyAttributeTypeToString(type: AttributeType): str {
    if type == AttributeType.String {
      return "S";
    } elif type == AttributeType.Number {
      return "N";
    } elif type == AttributeType.Binary {
      return "B";
    }
  }
}