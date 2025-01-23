## CloudFormation template
in folder deployment of project we have
- `dynamodb-tables.json`: CloudFormation template for creating DynamoDB tables (`Users` and `Rooms`) used by the chat server.
- `ec2-instance.json`: CloudFormation template for creating an EC2 instance to host your chat server
- `asg-elb.json`: CloudFormation template to add an Auto Scaling Group (ASG) and an Elastic Load Balancer (ELB) on top of your EC2 instance

## Steps to create DynamoDB tables on AWS using CloudFormation template

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


## Steps to create a EC2 Instance on AWS using CloudFormation template

### Validate the Template
Run the following command to validate the CloudFormation template:
```bash
aws cloudformation validate-template --template-body file://deployment/ec2-instance.json
```

### Create a Key Pair
If you don’t already have a key pair, create one to allow SSH access to the EC2 instance:
```bash
aws ec2 create-key-pair --key-name erl_server_ec2 --query "KeyMaterial" --output text > erl_server_ec2.pem
```

### Set Permissions on the Key File: Ensure the private key file has the correct permissions:
```bash
chmod 400 erl_server_ec2.pem
```

### Deploy the CloudFormation Stack: Create the EC2 instance using the updated CloudFormation template:
```bash
aws cloudformation create-stack --stack-name ChatServerEC2 \
    --template-body file://deployment/ec2-instance.json \
    --region us-east-1
```

### Get the Public IP: Once the stack is created, retrieve the public IP address of the instance:
```bash
aws cloudformation describe-stacks --stack-name ChatServerEC2 \
    --query "Stacks[0].Outputs[?OutputKey=='PublicIP'].OutputValue" --output text
```

### Connect to the EC2 Instance
```bash
ssh -i erl_server_ec2.pem ec2-user@<Public-IP>
```

### To delete the resources:
```bash
aws cloudformation delete-stack --stack-name ChatServerEC2
```


## Steps to add an Auto Scaling Group (ASG) and an Elastic Load Balancer (ELB) on top of your EC2 instance

### Validate the Template
Run the following command to validate the CloudFormation template:
```bash
aws cloudformation validate-template --template-body file://deployment/asg-elb.json
```

### Deploy the Stack using AWS CLI
```bash
aws cloudformation create-stack --stack-name ChatServerASGELB \
    --template-body file://deployment/asg-elb.json \
    --region us-east-1 \
    --capabilities CAPABILITY_NAMED_IAM
```

###  Validate the Deployment: Use the following command to ensure the stack is created successfully:
```bash
aws cloudformation describe-stacks --stack-name ChatServerASGELB
```

### To delete the resources:
```bash
aws cloudformation delete-stack --stack-name ChatServerASGELB
```
