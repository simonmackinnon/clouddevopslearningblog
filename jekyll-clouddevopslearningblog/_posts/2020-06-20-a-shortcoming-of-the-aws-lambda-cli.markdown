---
layout: post
title:  "A Shortcoming of the AWS Lambda CLI -  EventSourceMappings"
date:   2020-06-20 14:15:00 +1000
categories: aws lambda cli
tags: aws cli lambda
---
## A Shortcoming of the AWS Lambda CLI -  EventSourceMappings

This one only slightly annoyed me, but still thought it was worth mentioning.

Some things are really easy to in the console vs. via API calls. AWS Lambda "triggers" is a perfect example of this. The general steps are: create a Lambda function, open the Lambda function configuration in the console, click "Add Trigger", select source service and configure. Done!

![CodeCommit Trigger](/media/codecommittriggerconsole.png)

Being able to set up lambda triggers for a multitude of triggers from the Lambda console is a really nice (read: simple) way of configuring, and importantly, viewing, what services should be doing so, without having to navigate to each of the respective services' consoles themselves. When you add Lambda triggers in this way, you can see a visual list of all of the triggers as one of the first things in the Lambda console. Great, really nice UI/UX! 

![CodeCommit Trigger Created](/media/codecommittriggercreated.png)

So, now we want to replicate that experience using CloudFormation or API/CLI commands. You would be clever in thinking you can do all of this using the Lambda CLI, given you can do all this in the Lambda Console. And you'd also be wrong. The API call to produce this (listening) trigger is the [*CreateEventSourceMapping*](https://docs.aws.amazon.com/lambda/latest/dg/API_CreateEventSourceMapping.html), and the respective CLI command [create-event-source-mapping](https://docs.aws.amazon.com/cli/latest/reference/lambda/create-event-source-mapping.html). If you look at this documentation, you'll see that the only services for which you can create such a mapping, like you can in the console, is DynamoDB, Kinesis and SQS. Only those three... This is because Lambda service can essentially "read" events from these services, rather than be asyncronously or synchronously invoked by the triggering service.

{% highlight bash %}
aws lambda create-event-source-mapping \
    --function-name CodeCommitLambda-lambdacodecommit-OT2Z33UZKD9O \
    --batch-size 5 \
    --starting-position LATEST \
    --event-source-arn arn:aws:dynamodb:ap-southeast-2:366389342275:table/TestTable/stream/2020-06-20T04:50:40.178
{% endhighlight %}

![Dynamo Trigger Created](/media/dynamomappingcreated.png)

And, of course, you can set up triggers for each service respectively from the API calls for those services, but it only creates the one-way mapping. The Lambda function(s), in this case, have no knowledge or ownership of the triggers set up, for example, from CodeCommit.

{% highlight bash %}
aws codecommit put-repository-triggers \
    --repository-name my-webpage \
    --triggers name=MyLambdaTrigger,destinationArn="arn:aws:lambda:ap-southeast-2:123456789012:function:CodeCommitLambda-lambdacodecommit-OT2Z33UZKD9O",customData="",branches=master,events=all
{% endhighlight %} 

![CodeCommit Trigger](/media/codecommittrigger.png)

![No Mapping in Lambda](/media/lambdanotriggers.png)

Given this, it's disappointing that the Lambda console repsects the mapping for invoke-type triggers, but there's no way of even listing these kind "mappings" if you're doing function creation programatically.