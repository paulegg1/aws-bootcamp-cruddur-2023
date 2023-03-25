# Week 5 — DynamoDB and Serverless Caching


## DDB Local - Schema Load

The schema load for DDB is achieved by using the Boto3 library.  First, add boto3 to the requirements.txt and run pip install so that we have it available locally to work with.

<Show this>

Then using `backend-flask\bin\ddb\schema-load`, create the schema:



![DDB schema load](assets/ddb-schema-load-works.png)