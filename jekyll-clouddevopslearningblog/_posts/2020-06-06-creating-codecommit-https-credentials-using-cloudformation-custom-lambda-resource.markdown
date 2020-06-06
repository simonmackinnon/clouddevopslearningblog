---
layout: post
title:  "Creating CodeCommit HTTPS Security Credentials With CloudFormation Lambda-based Custom Resource"
categories: aws cloudformation
tags: aws cloudformation iam lambda
---
## Creating CodeCommit HTTPS Security Credentials With CloudFormation Lambda-based Custom Resource

![the outputs of the stack](/media/httpscreds.png)

As I have written previously, I've just committed myself to achieving the AWS DevOps Professional certification. As part of my study, I'm attempting to work through a [hands-on online course](https://www.udemy.com/course/aws-certified-devops-engineer-professional-hands-on/). I've also comitted to doing all demos using only the AWS CLI, SDK or CloudFormation. To force myself to to this, I've only granted programatic to my IAM user in my training account. The rationale is this: the console makes deploying things easy, and sets most default values for required fields in API calls appropriately. To get a better understanding of the services being used, provisioning in an automated way ensures these values need to be understood.

As I said, I started this course, primed to only work using scripts and Infrastructure as Code (with the aim of using CloudFormation primarily to ensure easy removal of deployed resources). The very first part of the very first demo: create an IAM User and create HTTPS CodeCommit Security Credentials for it. Easy, right? This is a two second job in the console. 

And, while there exists an API for this, [CreateServiceSpecificCredential](https://docs.aws.amazon.com/IAM/latest/APIReference/API_CreateServiceSpecificCredential.html), CloudFormation doesn't support this IAM feature. Enter, CloudFormation Custom Resources!

The steps needed for this resource could have been really simple, as the API call only requires an existing IAM user's username, and the endpoint of the AWS service to create the credentials for. I wanted to create a simple automation sequence to allow multiple users to be created with this stack.

I don't have a lot of experience writing Lambda code for CFN Custom Resources, so I used [crhelper](https://github.com/aws-cloudformation/custom-resource-helper) to help build out the function scaffolding. This library does a crazy amount of the undifferentiated heavy lifting. All that was required was to pass through the username to the create and reset credentials API calls (I used the Python SDK for this). 

![the outputs of the stack](/media/events.png)

The code was really simple:

{% highlight python %}
from crhelper import CfnResource
import boto3, json

helper = CfnResource()
iamclient = boto3.client('iam')

@helper.create
def create_https_credentials(event, _):
    user = event['ResourceProperties']['user']

    response = iamclient.create_service_specific_credential(
        UserName=user,
        ServiceName='codecommit.amazonaws.com'
    )

    helper.Data['ServiceUserName'] = response['ServiceSpecificCredential']['ServiceUserName']
    helper.Data['ServicePassword'] = response['ServiceSpecificCredential']['ServicePassword']

@helper.update
def reset_https_credentials(event, _):
    user = event['ResourceProperties']['user']
    
    response = iamclient.reset_service_specific_credential(
        UserName=user,
        ServiceName='codecommit.amazonaws.com'
    )

    helper.Data['ServiceUserName'] = response['ServiceSpecificCredential']['ServiceUserName']
    helper.Data['ServicePassword'] = response['ServiceSpecificCredential']['ServicePassword']

@helper.delete
def no_op(_, __):
    pass

def handler(event, context):
    print("Started execution of HTTPS Credentials Creator Lambda...")
    print("Function ARN %s" % context.invoked_function_arn)
    print("Incoming Event %s " % json.dumps(event))
    
    helper(event, context)
{% endhighlight %} 

You can check out (and use) the code for this here: [https://github.com/simonmackinnon/codecommit-httpscreds-cloudformation](https://github.com/simonmackinnon/codecommit-httpscreds-cloudformation). This repo has CloudFormation templates to deploy single-time resources, as well as to create an IAM user and output the corresponding Access Keys and the CodeCommit HTTPS Security Credentials. Feedback super welcome.

Anyway, at this rate, the 20-hour long course will probably take me about a year to complete, ha ha ha!