bring cloud;
bring "aws-cdk-lib" as awscdk;
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
  table: awscdk.aws_dynamodb.Table;
  tableName: str;
  partitionKeyName: str;
  sortKeyName: str?;

  init(props: DynamoDBTableProps) {
    let target = util.env("WING_TARGET");
    if target != "awscdk" {
      throw("Unsupported target: ${target} (expected: 'awscdk')");
    }

    this.partitionKeyName = props.partitionKey.keyName;
    
    let var sortKey: awscdk.aws_dynamodb.Attribute? = nil;
    if let sortKeyExists = props.sortKey {
      this.sortKeyName = sortKeyExists.keyName;
      sortKey = awscdk.aws_dynamodb.Attribute {
        name: sortKeyExists.keyName,
        type: this._keyAttributeTypeToString(sortKeyExists.type),
      };
    }
    
    this.table = new awscdk.aws_dynamodb.Table(
      billingMode: awscdk.aws_dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: awscdk.RemovalPolicy.DESTROY,
      partitionKey: awscdk.aws_dynamodb.Attribute {
        name: props.partitionKey.keyName,
        type: this._keyAttributeTypeToString(props.partitionKey.type)
      },
      sortKey: sortKey,
    );
    this.tableName = this.table.tableName;
  }

  _bind(host: std.IInflightHost, ops: Array<str>) {
    if let host = aws.Function.from(host) {
      if ops.contains(("putItem")) {
        host.addPolicyStatements([
          aws.PolicyStatement {
            actions: ["dynamodb:PutItem"],
            effect: aws.Effect.ALLOW,
            resources: [this.table.tableArn]
          }
        ]);
      }
    }
  }

  extern "./dynamodb.js" inflight _putItem(tableName: str, item: Json): void;
  inflight putItem(item: Json): void {
    this._putItem(this.tableName, item);
  }

  _keyAttributeTypeToString(type: AttributeType): awscdk.aws_dynamodb.AttributeType {
    if type == AttributeType.String {
      return awscdk.aws_dynamodb.AttributeType.STRING;
    } elif type == AttributeType.Number {
      return awscdk.aws_dynamodb.AttributeType.NUMBER;
    } elif type == AttributeType.Binary {
      return awscdk.aws_dynamodb.AttributeType.BINARY;
    }
  }
}