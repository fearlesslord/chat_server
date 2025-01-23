# Deployment Files

This directory contains infrastructure-related files for the project.

## Files

- `dynamodb-tables.json`: CloudFormation template for creating DynamoDB tables (`Users` and `Rooms`) used by the chat server.

## Usage

### Validate the Template
Run the following command to validate the CloudFormation template:
```bash
aws cloudformation validate-template --template-body file://deployment/dynamodb-tables.json
```

### Deploy the Stack using AWS CLI
```bash
aws cloudformation create-stack --stack-name ChatServerDynamoDB \
    --template-body file://deployment/dynamodb-tables.json \
    --region us-east-1
```

### Check the status of the stack
```bash
aws cloudformation describe-stacks --stack-name ChatServerDynamoDB --region us-east-1
```

###  Confirm that the tables were created:
```bash
aws dynamodb list-tables --region us-east-1
```