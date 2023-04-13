# Week 6 — Deploying Containers

## RDS Test Script ##

First thing to do is to create the RDS test script and get that working. It uses Python and gets the OS Env variable for our PSQL DB and then simply tries to connect.  As explained by Andrew, this allows us to test from the container without having to install PSQL client.

```python
#!/usr/bin/env python3

import psycopg
import os
import sys

connection_url = os.getenv("PROD_CONNECTION_URL")

conn = None
try:
  print('attempting connection')
  conn = psycopg.connect(connection_url)
  print("Connection successful!")
except psycopg.Error as e:
  print("Unable to connect to the database:", e)
finally:
  conn.close()
```

This worked straight away.

```sh
gitpod /workspace/aws-bootcamp-cruddur-2023/backend-flask/bin/db (main) $ ./test 
attempting connection
Connection successful!
```

## Health Check ##

We need a health check built into the app to allow our load balancers and/or other entities to check that our application is up/available.

This gets added at the end of the `app.py`

```python
@app.route('/api/health-check')
def health_check():
  return {'success': True}, 200
```

Also, a new script in `bin/flask` to call the health-check using Python, again for security considerations it is better to use python rather than install tools such as `curl`.  I created this in the basic form first, as per the video, but then changed it to include the try/catch from AB's recomendation.

```python
#!/usr/bin/env python3

import urllib.request

try:
  response = urllib.request.urlopen('http://localhost:4567/api/health-check')
  if response.getcode() == 200:
    print("[OK] Flask server is running")
    exit(0) # success
  else:
    print("[BAD] Flask server is not running")
    exit(1) # false
except Exception as e:
  print(e)
  exit(1) # false
```
This worked first time, and you can test by running it:

```sh
gitpod /workspace/aws-bootcamp-cruddur-2023/backend-flask/bin/flask (main) $ ./health-check 
Flask server is running
gitpod /workspace/aws-bootcamp-cruddur-2023/backend-flask/bin/flask (main) $ echo $?
0
```

## CloudWatch Group ##

Create the cloudwatch group :

```sh
aws logs create-log-group --log-group-name /cruddur/fargate-cluster
aws logs put-retention-policy --log-group-name /cruddur/fargate-cluster --retention-in-days 1
```

## Create Cluster ##

Using the AWS, now create the cluster.

``sh
aws ecs create-cluster \
--cluster-name cruddur \
--service-connect-defaults namespace=cruddur
```

This worked (although I needed to retry once);

```sh
gitpod /workspace/aws-bootcamp-cruddur-2023/backend-flask/bin/flask (main) $ aws ecs create-cluster --cluster-name cruddur --service-connect-defaults namespace=cruddur
{
    "cluster": {
        "clusterArn": "arn:aws:ecs:us-east-1:540771840545:cluster/cruddur",
        "clusterName": "cruddur",
        "status": "PROVISIONING",
...
```

Now, in the console you should have an ECS cluster and a generated namespace shown in the ECS console. The namespace also appears in the AWS console under `AWS Cloud Map`, so go and take a look there too.

SKIPPED THESE, but left them for reference:

```sh
export CRUD_CLUSTER_SG=$(aws ec2 create-security-group \
  --group-name cruddur-ecs-cluster-sg \
  --description "Security group for Cruddur ECS ECS cluster" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_CLUSTER_SG
```

```sh
export CRUD_CLUSTER_SG=$(aws ec2 describe-security-groups \
--group-names cruddur-ecs-cluster-sg \
--query 'SecurityGroups[0].GroupId' \
--output text)
```


# Working with ECS Fargate #

##  Create new ECRs for our containers ##

There will be three repos to create.  
 - One for base-image python
 - One for Flask
 - One for React

### Base Image Python ECR ##

Remember direct from Docker Hub was `FROM python:3.10-slim-buster`.  We will host our own in our own ECR, removing reliance on Docker Hub.

So,  create the repo:

```sh
aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
```

This should look like this:

```sh
$ aws ecr create-repository \
  --repository-name cruddur-python \
  --image-tag-mutability MUTABLE
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:540771840545:repository/cruddur-python",
        "registryId": "540771840545",
        "repositoryName": "cruddur-python",
        "repositoryUri": "540771840545.dkr.ecr.us-east-1.amazonaws.com/cruddur-python",
        "createdAt": "2023-04-13T06:44:04+00:00",
        "imageTagMutability": "MUTABLE",
        "imageScanningConfiguration": {
            "scanOnPush": false
        },
        "encryptionConfiguration": {
            "encryptionType": "AES256"
        }
    }
}
```
You can now see the new repository in the AWS Console under ECS / ECR.  You can use the console to take a look at the push/pull ECR commands.

Now, grab the URL as an OS Env Var.

```sh
export ECR_PYTHON_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/cruddur-python"
echo $ECR_PYTHON_URL
```

Now we can login to ECR which is a requirement (of course) for us to be able to push/pull containers:

```sh
aws ecr get-login-password --region $AWS_DEFAULT_REGION |  docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com"
```
Be aware that your unencrypted password is stored locally :  `WARNING! Your password will be stored unencrypted in /home/gitpod/.docker/config.json.`

Now Pull the base python down (it isn't our own, so we pull it from DH)

```sh
docker pull python:3.10-slim-buster
```

Then tag it:

```sh
 docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster
```

And push it up to our ECR:

```sh

$ docker push $ECR_PYTHON_URL:3.10-slim-buster
The push refers to repository [540771840545.dkr.ecr.us-east-1.amazonaws.com/cruddur-python]
7f2fe4cb548a: Pushed 
c7787300a586: Pushed 
039e9922562b: Pushed 
ccc60df26c61: Pushed 
61a5c84a1270: Pushed 
3.10-slim-buster: digest: sha256:7857e9a198fc4b06818b0e064c13b21485b72c7fdb1f51d3b13c9854ca2fcfa5 size: 1370
gitpod /workspace/aws-bootcamp-cruddur-2023/backend-flask/bin/flask (main) $ 

```

You will now see the image in the ECR in AWS Console, go and check.

![ECR has Slim Buster](assets/ecr-slim-buster.png)

### Base Image Python ECR ##

Now we need to push an image of our Flash app up to ECR.

First we need to edit the Dockerfile and replace the DH reference to slim-buster with our own ECR-stored copy.  This means our Flask app will now use our ECR-stored slim-buster container.

The top of the DockerFile in `backend-flask` needs this as the top line:

```DockerFile
FROM 540771840545.dkr.ecr.us-east-1.amazonaws.com/cruddur-python:3.10-slim-buster

WORKDIR /backend-flask
```

Of course it will vary. It is the repository URI from either the AWS console or get it from our Env Var, PLUS the image name

```sh
$ echo $ECR_PYTHON_URL
540771840545.dkr.ecr.us-east-1.amazonaws.com/cruddur-python
```

It is also possible to get the repo URI this using:

```sh
aws ecr describe-repositories --repository-name cruddur-python --query 'repositories[0].repositoryUri'
```



Next, create the Flask Repo:

```sh
aws ecr create-repository \
  --repository-name backend-flask \
  --image-tag-mutability MUTABLE
```


