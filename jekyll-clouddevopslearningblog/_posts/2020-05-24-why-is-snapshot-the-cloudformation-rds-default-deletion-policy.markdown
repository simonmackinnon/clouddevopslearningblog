---
layout: post
title:  "Why (the Hell) is Snapshot the CloudFormation RDS Default Deletion Policy??"
date:   2020-05-24 14:00:00 +1000
categories: aws cloudformation
---
**Why (the Hell) is Snapshot the CloudFormation RDS Default Deletion
Policy??**

This one blew me away. If you create an RDS instance using any other
method, the default deletion behaviour is just to delete. If you create
the same configured instance using CloudFormation, the default deletion
behaviour is to create a manual snapshot.

I was happily working through an A Cloud Guru [CloudFormation
course](https://learn.acloud.guru/course/aws-advanced-cloudformation/dashboard),
spinning up CFN stack after CFN stack. In between I was deleting the
stacks, thinking this was cleaning up my environment. Little did I know,
there were RDS snapshots being created each time I killed my "immutable"
infrastructure.

![All the snapshots!](/media/snapshots.png)

So, after plugging away at the course, I found that the default Deletion
Policy for resources created using CloudFormation is to delete... Except
for RDS... Grrrr!

In order to ensure my test infrastructure was properly cleaned up after
being done, I had to ensure the DeletionPolicy field was manually set to
"Delete" for the RDS instances being created:
{% highlight yaml %}
Resources:
    DB:
        Type: \"AWS::RDS::DBInstance\"
        DeletionPolicy: Delete
        Properties:
            ...
{% endhighlight %}

The [AWS documentation for Deletion
Policies](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html)
says that:

*"The default policy is Snapshot for AWS::RDS::DBCluster resources and
for AWS::RDS::DBInstance resources that don\'t specify
the DBClusterIdentifier property."*

What's crazy is that this isn't evident unless you see the snapshots
being created. The CFN events for the stack don't show the snapshot
being created, just the DB being deleted:

![Deleting the database, no snapshot info](/media/databasedelete.png)

I can (kind of) understand why AWS would want a snap to be taken before
deleting a stack. Data loss is likely a bigger issue for them than an
extra storage cost would be. I just think they'd have done a better job
making this default behaviour salient, especially for those just getting
started with CloudFormation.

Alright, off to delete some RDS snapshots...
