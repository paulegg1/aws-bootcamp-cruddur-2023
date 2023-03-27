# Week 5 — DynamoDB and Serverless Caching


## DDB Local - Schema Load

The schema load for DDB is achieved by using the Boto3 library.  First, add boto3 to the requirements.txt and run pip install so that we have it available locally to work with.

<Show this>

Then using `backend-flask\bin\ddb\schema-load`, create the schema:



![DDB schema load](assets/ddb-schema-load-works.png)




## Cognito List Users

The cognito list users is a neat utility script that uses boto3 to grab our Cognito User details from the cognito pool. It relies on being able to get the Cognito Pool ID from the os.env.  This was also populated into 'gp env' as `AWS_COGNITO_USER_POOL_ID=us-east-1_dh4fakeidP`.  It works as expected and is called as a script under `~/bin/cognito/list-users`.

