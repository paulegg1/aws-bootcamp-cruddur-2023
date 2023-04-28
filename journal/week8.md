# Week 8 — Serverless Image Processing

## CDK Getting Started ##

CDK is an open source development framework that is used to write IaC. It can be used with a number of imperative programming languages such as Python, Typescript and Java.  We will use it in this project with Typescript to deliver the resources required for the Image Processing parts of the application.

### File Structure and npm install ##

First, we need a new directory to store all our CDK related stuff:

```sh
cd /workspace/aws-bootcamp-cruddur-2023
mkdir thumbing-serverless-cdk
```

Next, we need to install the npm module for `aws-cdk`:

```sh
npm install aws-cdk -g
```

Plus we need this to be installed on every new Gitpod environment we launch, so add the following to the `.gitpod.yml` (we will need the dotenv later too):

```yaml
  - name: cdk
    before: |
      npm install aws-cdk -g
      npm install dotenv
```

### Start a new project with cdk init ###

The way to initialize a new cdk project is as shown below, do this from within the new folder.  Note how we can pass the language to the command, as mentioned before, this could be python, java or other languages.

```sh
cdk init app --language typescript
```

## Adding the first resource - s3 ##

The best way to get started is to create the s3 bucket that we need for the image processing part of the project.  The deliver of an s3 bucket using CDK is really straight forward. Edit `thumbing-serverless-cdk/lib/thumbing-serverless-cdk-stack.ts` and add the following _after_ the constructor:

```typescript
  createBucket(bucketName: string): s3.IBucket {
    const bucket = new s3.Bucket(this, 'ThumbingBucket', {
      bucketName: bucketName,
      removalPolicy: cdk.RemovalPolicy.DESTROY

    });
    return bucket;
  }
```

We will need to import `aws-s3` at the top of the file:

```typescript
import * as s3 from 'aws-cdk-lib/aws-s3';
```

plus we will need to pull in the required environment variables and call our new function from inside the constructor:

```typescript
...
const bucketName: string = process.env.THUMBING_BUCKET_NAME as string;
    const bucket = this.createBucket(bucketName);
...
```

On the commmand line, if we add the environment variable to our shell (and persistent gitpod variables, we can test):

```sh
export THUMBING_BUCKET_NAME="cruddur-thumbs"
gp env THUMBING_BUCKET_NAME="cruddur-thumbs"
```

The full file currently looks like this:

```typescript
import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import { Construct } from 'constructs';

export class ThumbingServerlessCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here

    const bucketName: string = process.env.THUMBING_BUCKET_NAME as string;
   
    const bucket = this.createBucket(bucketName);
    
  }

  createBucket(bucketName: string): s3.IBucket {
    const bucket = new s3.Bucket(this, 'ThumbingBucket', {
      bucketName: bucketName,
      removalPolicy: cdk.RemovalPolicy.DESTROY

    });
    return bucket;
  }
```

## bootstrapping ##

CDK requires some resources in your AWS account in order to operate.  To create this (a one-time, per-region task), we need to bootstrap the environment.  This is done as follows:

```sh
cdk bootstrap "aws://$AWS_ACCOUNT_ID/$AWS_DEFAULT_REGION"
```

Once that is done, go and look at your CloudFormation stacks in AWS, you should see a new cdk stack present.

## CDK synth ##

CDK leverages CloudFormation.  Fundamentally what is happening when you use CDK is that you are using an imperative programming language to build out CloudFormation stacks for you.  "Synthesising" a CF Stack is the first step in a CDK build process and you can (and should for testing) run the `cdk synth` process manually.

To run CDK synth and see the YAML output that represents the synthesised CloudFormation template, run this:

```sh
cdk synth
```

The output should look a little like this (truncated):

```sh
gitpod /workspace/aws-bootcamp-cruddur-2023/thumbing-serverless-cdk (main) $ cdk synth
Resources:
  ThumbingBucket715A2537:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: paulegg-cruddur-thumbs
    UpdateReplacePolicy: Delete
...
```

## CDK deploy ##

Once you're happy with the output of the `cdk synth`, you are ready to run the deploy in order to actually create the resources you have developed in your Typescript code.  Run this:

```sh
cdk deploy
```

This should build and deploy your bucket. Go to the AWS console and check the cloud formation stacks to see.

The shell console should look something like this:

```sh
gitpod /workspace/aws-bootcamp-cruddur-2023/thumbing-serverless-cdk (main) $ cdk deploy

✨  Synthesis time: 8.37s

ThumbingServerlessCdkStack: building assets...

[0%] start: Building 796b68018ce7acbc0c09c44a6bd4e0080cca521b14ecff38b78b35daadcf7cec:current_account-current_region
[100%] success: Built 796b68018ce7acbc0c09c44a6bd4e0080cca521b14ecff38b78b35daadcf7cec:current_account-current_region

ThumbingServerlessCdkStack: assets built

ThumbingServerlessCdkStack: deploying... [1/1]
[0%] start: Publishing 796b68018ce7acbc0c09c44a6bd4e0080cca521b14ecff38b78b35daadcf7cec:current_account-current_region
[100%] success: Published 796b68018ce7acbc0c09c44a6bd4e0080cca521b14ecff38b78b35daadcf7cec:current_account-current_region
ThumbingServerlessCdkStack: creating CloudFormation changeset...

 ✅  ThumbingServerlessCdkStack

✨  Deployment time: 45.33s

Stack ARN:
arn:aws:cloudformation:us-east-1:540771840545:stack/ThumbingServerlessCdkStack/94d21850-e529-11ed-a29a-0af8609542bf

✨  Total time: 53.7s


...


```


##  Adding Lambda ##


First, just to test CDK and adding a Lambda I added a simple hello world Lambda to get started:

```typescript
exports.handler = function(event, context) {
    context.succeed("Hello, World!");
   };
```

Output:

```sh
IAM Statement Changes
┌───┬────────────────────────────────┬────────┬────────────────┬──────────────────────────────┬───────────┐
│   │ Resource                       │ Effect │ Action         │ Principal                    │ Condition │
├───┼────────────────────────────────┼────────┼────────────────┼──────────────────────────────┼───────────���
│ + │ ${ThumbLambda/ServiceRole.Arn} │ Allow  │ sts:AssumeRole │ Service:lambda.amazonaws.com │           │
└───┴────────────────────────────────┴────────┴────────────────┴──────────────────────────────┴───────────┘
IAM Policy Changes
┌───┬────────────────────────────┬────────────────────────────────────────────────────────────────────────────────┐
│   │ Resource                   │ Managed Policy ARN                                                             │
├───┼────────────────────────────┼────────────────────────────────────────────────────────────────────────────────┤
│ + │ ${ThumbLambda/ServiceRole} │ arn:${AWS::Partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole │
└───┴────────────────────────────┴────────────────────────────────────────────────────────────────────────────────┘
(NOTE: There may be security-related changes not in this list. See https://github.com/aws/aws-cdk/issues/1299)

Do you wish to deploy these changes (y/n)? y
ThumbingServerlessCdkStack: deploying... [1/1]
[0%] start: Publishing a053d6a01dd31d2892bb3ae3e75d1e735ecf499b5c278a054a21428c31422521:current_account-current_region
[0%] start: Publishing 932e44935f3f76104a4403cb03cfe399445e634d7f70110790bd61e4489c21cf:current_account-current_region
[50%] success: Published 932e44935f3f76104a4403cb03cfe399445e634d7f70110790bd61e4489c21cf:current_account-current_region
[100%] success: Published a053d6a01dd31d2892bb3ae3e75d1e735ecf499b5c278a054a21428c31422521:current_account-current_region
ThumbingServerlessCdkStack: creating CloudFormation changeset...

 ✅  ThumbingServerlessCdkStack

✨  Deployment time: 56.56s

Stack ARN:
arn:aws:cloudformation:us-east-1:540771840545:stack/ThumbingServerlessCdkStack/94d21850-e529-11ed-a29a-0af8609542bf

✨  Total time: 62.96s
```

## The real lambda ##

In `aws/lambdas/thumbLambda` is the lambda code for the image processing.

You will need to add the node modules required for the Lambda in that location:

```sh
npm i sharp
npm i @aws-cdk/s3-client
```

That will create the `node_modules` directory and place the dependencies into `package.json`

```json
...
  "dependencies": {
    "@aws-sdk/client-s3": "^3.321.1",
    "sharp": "^0.32.1"
  }
...
```

Next, go back to the thumbing stack and re-run `cdk deploy`

