
# Week 0 — Billing and Architecture

## Required Homework/Tasks

### GitPod and AWS CLI

GitPod was entirely new to me, but the Youtube videos made it easy to get up and running.  I am now editing my journal entries in my GitPod workspace instead of a local VScode install.

I've also previously used the AWS CLI, but now I needed to get this working in the GitPod workspace, again the edits to gitpod.yml provided by AB made it easy to get this installed, here is an example of the AWS CLI working with my new AWS user:

![AWS CLI in GitPod](assets/awscli-gitpod-01.png)

I've used the environment variables in GP to store my AWS credentials and configured GP env to remember them across relaunch.

### Billing Alarms 

I have enabled the billing alert preferences in Billing -> Billing Preferences

### SNS Topic Creation

I completed this, straightforwardly in the AWS CLI while using my GP workspace:

```sh
aws sns create-topic --name billing-alarm
```
Here's the image:

![AWS CLI in GitPod](assets/create-sns-topic-01.png)


Using the following, I've created the subscription against my own email:

```sh
aws sns subscribe \
    --topic-arn TopicARN \
    --protocol email \
    --notification-endpoint myname@myemail.com
```

Here's the image:

![AWS CLI in GitPod](assets/create-sns-topic-02.png)

I confirmed this in my email.


### Recreate Conceptual Architectural Design - Napkin

![Cruddur Conceptual Design](assets/conceptual-napkin-architecture-recreation-diag.png)


### Recreate Logcal Architectural Diagram - Lucid

![Cruddur Conceptual Design](assets/Cruddur-Logical-Diagram.png)

[Lucid Charts Share Link](https://lucid.app/lucidchart/431475ba-5e01-4738-8b24-c06acb84100c/edit?viewport_loc=-282%2C-86%2C2408%2C1592%2C0_0&invitationId=inv_2df85908-1a39-4f63-8b20-ae36742f2ed1)
 