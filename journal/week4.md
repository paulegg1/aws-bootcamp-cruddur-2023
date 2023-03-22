# Week 4 — Postgres and RDS

Week 4.  A quick introduction. This has been a very big week in the development of this application.  There was a lot to do and a lot was covered.  I ran late and am behind on completing the homework tasks and submitting them.  However, it has also been a week when I've learnt a lot.  Some python, some Lambda and RDS too.  Anyway, let's get into the weeds and document what was done!

## Creation of RDS instance

One of the first tasks was to create an RDS instance in AWS for the PostgresSQL backend OLTP DB.  There are a number of ways to complete this, namely the AWS console, the aws cli, or - one of my favourites, using Terraform.

I used the following command as my guide to create a Terraform TF file that would be able to deploy my database:


```sh
aws rds create-db-instance \
  --db-instance-identifier test-cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username root \
  --master-user-password mypasswordhere \
  --allocated-storage 20 \
  --availability-zone us-east-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
  ```

This translated into the following TF :

```terraform
resource "aws_db_instance" "postgres" {
  identifier                            = "cruddur-db-instance"
  instance_class                        = "db.t3.micro"
  engine                                = "postgres"
  engine_version                        = 14.6
  username                              = "root"
  password                              = "SuperSecretPassword"
  allocated_storage                     = 20
  availability_zone                     = "us-east-1a"
  backup_retention_period               = 0
  port                                  = 5432
  db_subnet_group_name                  = aws_db_subnet_group.cruddur_dbsn_group.name
  db_name                               = "cruddur"
  storage_type                          = "gp2"
  publicly_accessible                   = true
  storage_encrypted                     = true
  performance_insights_retention_period = 7
  performance_insights_enabled          = true
  deletion_protection                   = false
  skip_final_snapshot                   = true
  vpc_security_group_ids = [ aws_security_group.allow_postgres.id ]
}
```

I also have the security group as follows (although later we include some AWS CLI to change the source IP on demand):

```terraform

resource "aws_security_group" "allow_postgres" {
  name        = "allow_postgres"
  description = "Allow postgres inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "postgres from GP"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = ["35.240.58.185/32"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_postgres"
  }
}
```

This deployed successfully and I have a running PostgreSQL RDS instance for our production DB.

## Some utility DB management scripts

I wrote, using the guidance from the live stream, several DB utility bash scripts under `backend-flask/bin/`.  Mostly these are the same as the ones written during the livestream, but I've used `DIRECTORY=$(cd `dirname $0` && pwd)` instead of `realpath` because it lets me run the scripts from anywhere within the tree without relying on relative paths.

The files created were:

```sh
backend-flask/bin:
db-connect
db-create
db-drop
db-schema-load
db-seed
db-showconns
dirname
doit-all
```
Where doit-all is a call to db-drop, db-create, db-schema-load and db-seed.  The idea is to create a set of DDL tools that allow a `reset` of the database as well as individual actions to connect, create, drop etc. 

I won't detail them all here, they can be seen in the repo, but here's `db-schema-load` :

```sh
#! /usr/bin/bash

#echo "== db-schema-load"
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

DIRECTORY=$(cd `dirname $0` && pwd)

schema_path="${DIRECTORY}/../db/schema.sql"


if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $schema_path
```

You can see that it references a file called `schema.sql`; this is a file containing the SQL required to build the schema for our database:

```sh
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- forcefully drop our tables if they already exist
DROP TABLE IF EXISTS public.users cascade;
DROP TABLE IF EXISTS public.activities;

CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text,
  handle text,
  cognito_user_id text,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```
There is also `seed.sql` that was used to create some very basic early user data entries:

```sh
-- this file was manually created
INSERT INTO public.users (display_name, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko', 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
  ```
  
  Finally, I began on the utility methods, `db.py`, this changes heavily, but the first incantation of this looked as follows:
  
  ```python
  from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = '''
  (SELECT COALESCE(row_to_json(object_row),'{}'::json) FROM (
  {template}
  ) object_row);
  '''

def query_wrap_array(template):
  sql = '''
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  '''

connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```

## RDS DB Security

As shown above in the TF excerpt, there is a security group associated with the RDS instance that prevents global access to the DB port.  The IP used was my initial Gitpod IP.  I realised from the beginning that there would be a need to change that IP by grabbing the GitPod IP on every workspace launch and changing the source IP in the security group rule.  Fortunately this was solved for me before I had chance to work on it by `Brown/Bayko` :) with an aws cli call.  The call was wrapped in a script that can be called on workspace launch in `gitpod.yml`:

```yaml
    command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source "$THEIA_WORKSPACE_ROOT/backend-flask/db-update-sg-rule"
```
The script:

```sh
aws ec2 modify-security-group-rules --group-id $DB_SG_ID --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```

It relies on a few new `gp env` environment variables, 

```sh
export DB_SG_ID="sg-0b1234..."
gp env DB_SG_ID="sg-0b1234..."
export DB_SG_RULE_ID="sgr-07005678..."
gp env DB_SG_RULE_ID="sgr-07005678..."
```

## Begin DB integration

Now that we had some DB tools, a remote DB, a method to access etc, it was time to start replacing the mocked results json returns from the various python backend endpoints with data pulled from the DB.  The first step was to remove the hard coded `results` json with a call to the db from our db library.
 
First the import, starting with `home_activities.py`;

```python
from datetime import datetime, timedelta, timezone
from opentelemetry import trace

from lib.db import pool, query_wrap_array
import logging
```

Then, we construct the sql statement and use the db library (which has a connection URL from the env var `CONNECTION_URL`) to get the connection pool and execute the SQL.

oh, an aside, that `CONNECTION_URL` comes from the `gp env` and is passed through to docker-compose.  First, gp env:

Standard:

```sh
Connection URL String

```sh
export CONNECTION_URL="postgresql://postgres:pssword@127.0.0.1:5432/cruddur"
gp env CONNECTION_URL="postgresql://postgres:pssword@127.0.0.1:5432/cruddur"
```


Prod:

```sh
export PROD_CONNECTION_URL="postgresql://root:huEE33z2Qvl383@cruddur-db-instance.c4igg9l0qway.us-east-1.rds.amazonaws.com:5432/cruddur"
gp env PROD_CONNECTION_URL="postgresql://root:huEE33z2Qvl383@cruddur-db-instance.c4igg9l0qway.us-east-1.rds.amazonaws.com:5432/cruddur"
```

Then the docker-compose file, showing when we're ready for PROD conn:

```diff
 services:
   backend-flask:
     environment:
+      CONNECTION_URL: "${PROD_CONNECTION_URL}"
       FRONTEND_URL: "https://3000-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
       BACKEND_URL: "https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
```

..Back to the DB connection in `home_activities.py`,

This method successfully returned a single row for us from the DB:

```python
...
  sql = query_wrap_array("""
      SELECT
        *
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
	    """)
      print(sql)
      
      with pool.connection() as conn:
        with conn.cursor() as cur:
          cur.execute(sql)
          # this will return a tuple
          # the first field being the data
          json = cur.fetchone()
          home_logger.info("======= NOT JSON =====")
          home_logger.info(json)    
      return json[0] 

...
```

## Lambda and post confirmation trigger

We now needed a Lambda and a post user sign up / confirmation trigger to write our cognito user details into our backend PGSQL DB.  Cognito can easily be setup to be integrated with Lambda and call a function on confirmation.  That function, in our case, writes the user details into the DB.  The Lambda looks as follows:

```python
import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes')
    print(user)

    user_display_name  = user['name']
    user_email         = user['email']
    user_handle        = user['preferred_username']
    user_cognito_id    = user['sub']
    try:
      sql = f"""
         INSERT INTO public.users (
          display_name, 
          email,
          handle, 
          cognito_user_id
          ) 
        VALUES(%s,%s,%s,%s)
      """

      conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
      cur = conn.cursor()
      params = [
        user_display_name,
        user_email,
        user_handle,
        user_cognito_id
      ]
      cur.execute(sql,*params)
      conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
      print(error)
    finally:
      if conn is not None:
          cur.close()
          conn.close()
          print('Database connection closed.')
    return event
    
```

I had a number of issues with this, I also know a number of other students hit similar issues.  The first was an error, shown in cloudwatch logs as `function takes at most 2 arguments (5 given)`.

What was required the addition of an email columan the schema.sql, note also that `seed.sql` needed those new columns adding to include the email address (not shown here):

```diff
   uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
   display_name text,
   handle text,
+  email text,
   cognito_user_id text,
   created_at TIMESTAMP default current_timestamp NOT NULL
);
```


Once the lambda function triggered correctly, I successfully had a new entry in the table:


![Lambda works](assets/lambda-function-works.png)

## db.py refactor

Next, following Andrew's video, I refactored the db.py into a Python class, and imported that new class into the `home_activites.py` and `create_activities.py` files:

```diff

- from lib.db import pool, query_wrap_array
  import logging
+ from lib.db import db


```

The rewrite of the db library uses a template mechanism to load the SQL code in from some utility SQL files.  These are:

`db/sql/activities/create.sql`  - for inserting a new activity/post:

```sql

INSERT INTO public.activities (
  user_uuid,
  message,
  expires_at
)
VALUES (
  (SELECT uuid 
    FROM public.users 
    WHERE users.handle = %(handle)s
    LIMIT 1
  ),
  %(message)s,
  %(expires_at)s
) RETURNING uuid;
```

`db/sql/activities/home.sql`  - for selecting the required activities/posts for the home screen:

```sql
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.replies_count,
  activities.reposts_count,
  activities.likes_count,
  activities.reply_to_activity_uuid,
  activities.expires_at,
  activities.created_at
FROM public.activities
LEFT JOIN public.users ON users.uuid = activities.user_uuid
ORDER BY activities.created_at DESC
```

and `db/sql/activities/object.sql`  - for selecting a single activity by unique id:


```sql
SELECT
  activities.uuid,
  users.display_name,
  users.handle,
  activities.message,
  activities.created_at,
  activities.expires_at
FROM public.activities
INNER JOIN public.users ON users.uuid = activities.user_uuid 
WHERE 
  activities.uuid = %(uuid)s

```

The application works and I can sign up and login, post and view new posts, all using the RDS DB !!  

