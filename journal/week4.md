# Week 4 — Postgres and RDS



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

Connection URL String

```sh
export CONNECTION_URL="postgresql://postgres:pssword@127.0.0.1:5432/cruddur"
gp env CONNECTION_URL="postgresql://postgres:pssword@127.0.0.1:5432/cruddur"
```
