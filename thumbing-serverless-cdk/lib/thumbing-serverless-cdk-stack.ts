import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as s3n from 'aws-cdk-lib/aws-s3-notifications'
import * as sns from 'aws-cdk-lib/aws-sns';
import * as subscriptions from 'aws-cdk-lib/aws-sns-subscriptions';
import * as lambda from 'aws-cdk-lib/aws-lambda'
import { Construct } from 'constructs';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as dotenv from 'dotenv';
// import * as sqs from 'aws-cdk-lib/aws-sqs';

//without this we would need to cp .env.example to .env in the .gitpod.yml
dotenv.config({path: '.env.example'});

export class ThumbingServerlessCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here

    
    const bucketName: string = process.env.THUMBING_BUCKET_NAME as string;
    const functionPath: string = process.env.THUMBING_FUNCTION_PATH as string;
    const folderInput: string = process.env.THUMBING_FOLDER_INPUT as string;
    const folderOutput: string = process.env.THUMBING_FOLDER_OUTPUT as string;
    const webhookUrl: string = process.env.THUMBING_WEBHOOK_URL as string;
    const topicName: string = process.env.THUMBING_TOPIC_NAME as string;
    //const bucket = this.createBucket(bucketName);
    const bucket = this.importBucket(bucketName);
    const lambda = this.createLambda(functionPath, bucketName, folderInput, folderOutput);

    const snsTopic = this.createSnsTopic(topicName)
    this.createSnsSubscription(snsTopic,webhookUrl)

    // Create required Policies
    const s3ReadWritePolicy = this.createPolicyBucketAccess(bucket.bucketArn)
    const snsPublishPolicy = this.createPolicySnSPublish(snsTopic.topicArn)

    // S3 Events
    this.createS3NotifyToLambda(folderInput,lambda,bucket)
    this.createS3NotifyToSns(folderOutput,snsTopic,bucket)
    
    //Attach required policies
    lambda.addToRolePolicy(s3ReadWritePolicy);
    lambda.addToRolePolicy(snsPublishPolicy);
   
  }

  
  //createBucket(bucketName: string): s3.IBucket {
  //  const bucket = new s3.Bucket(this, 'ThumbingBucket', {
  //    bucketName: bucketName,
  //    removalPolicy: cdk.RemovalPolicy.RETAIN
  //
  //  });
  //  return bucket;
  //}
  
  importBucket(bucketName: string): s3.IBucket {
    const bucket = s3.Bucket.fromBucketName(this, 'ThumbingBucket', bucketName);
    return bucket;
  }

  createLambda(functionPath: string, bucketName: string, folderInput: string, folderOutput: string): lambda.IFunction {
    const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
      code: lambda.Code.fromAsset(functionPath),
      handler: 'index.handler',
      runtime: lambda.Runtime.NODEJS_18_X,
      environment: {
        DEST_BUCKET_NAME: bucketName,
        FOLDER_INPUT: folderInput,
        FOLDER_OUTPUT: folderOutput,
        PROCESS_WIDTH: '512',
        PROCESS_HEIGHT: '512',

      }
    });
    return lambdaFunction; 
  }

  // Adds a notification event based on our prefix (original image folder location), PUT type and bucket name
  createS3NotifyToLambda(prefix: string, lambda: lambda.IFunction, bucket: s3.IBucket): void {
    const destination = new s3n.LambdaDestination(lambda);
    bucket.addEventNotification(
      s3.EventType.OBJECT_CREATED_PUT,
      destination,
      {prefix: prefix}
    );
  }

  createPolicyBucketAccess(bucketArn: string){
    const s3ReadWritePolicy = new iam.PolicyStatement({
      actions: [
        's3:GetObject',
        's3:PutObject',
      ],
      resources: [
        `${bucketArn}/*`,
      ]
    });
    return s3ReadWritePolicy;
  }


  createS3NotifyToSns(prefix: string, snsTopic: sns.ITopic, bucket: s3.IBucket): void {
    const destination = new s3n.SnsDestination(snsTopic)
    bucket.addEventNotification(
      s3.EventType.OBJECT_CREATED_PUT, 
      destination,
      {prefix: prefix}
    );
  }

  createSnsTopic(topicName: string): sns.ITopic{
    const logicalName = "ThumbingTopic";
    const snsTopic = new sns.Topic(this, logicalName, {
      topicName: topicName
    });
    return snsTopic;
  }

  createSnsSubscription(snsTopic: sns.ITopic, webhookUrl: string): sns.Subscription {
    const snsSubscription = snsTopic.addSubscription(
      new subscriptions.UrlSubscription(webhookUrl)
    )
    return snsSubscription;
  }

  createPolicySnSPublish(topicArn: string){
    const snsPublishPolicy = new iam.PolicyStatement({
      actions: [
        'sns:Publish',
      ],
      resources: [
        topicArn
      ]
    });
    return snsPublishPolicy;
  }

} 
