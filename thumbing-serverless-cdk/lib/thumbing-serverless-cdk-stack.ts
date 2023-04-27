import * as cdk from 'aws-cdk-lib';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as lambda from 'aws-cdk-lib/aws-lambda'
import { Construct } from 'constructs';
import { LambdaApplication } from 'aws-cdk-lib/aws-codedeploy';
// import * as sqs from 'aws-cdk-lib/aws-sqs';

export class ThumbingServerlessCdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // The code that defines your stack goes here

    
    const bucketName: string = process.env.THUMBING_BUCKET_NAME as string;
    const functionPath: string = process.env.THUMBING_FUNCTION_PATH as string;
    const bucket = this.createBucket(bucketName);
    const lambda = this.createLambda(functionPath);

    // REMOVE THIS:
    // example resource
    // const queue = new sqs.Queue(this, 'ThumbingServerlessCdkQueue', {
    //   visibilityTimeout: cdk.Duration.seconds(300)
    // });
  }

  createBucket(bucketName: string): s3.IBucket {
    const bucket = new s3.Bucket(this, 'ThumbingBucket', {
      bucketName: bucketName,
      removalPolicy: cdk.RemovalPolicy.DESTROY

    });
    return bucket;
  }


  createLambda(functionPath: string): lambda.IFunction {
    const lambdaFunction = new lambda.Function(this, 'ThumbLambda', {
      code: lambda.Code.fromAsset(functionPath),
      handler: 'index.handler',
      runtime: lambda.Runtime.NODEJS_18_X,
    });
    return lambdaFunction; 
  }

} 
