---
layout: post
title:  "Course Review: A Cloud Guru, Advanced AWS CloudFormation- Adrian Cantrill"
date:   2020-05-28 20:15:00 +1000
categories: aws cloudformation
---
## Course Review: A Cloud Guru, Advanced AWS CloudFormation- Adrian Cantrill
### Course URL: [https://learn.acloud.guru/course/aws-advanced-cloudformation/dashboard](https://learn.acloud.guru/course/aws-advanced-cloudformation/dashboard)

### TL;DR
Do this course! Awesome and fun content using practical templates provided and evolved to match the skills being taught. Perfect course introducing some complex and advances topics for AWS CloudFormation. Thanks Adrian!

### Long Version

After completing the AWS Associate Certification trifecta late last year, and Azure Fundamentals earlier this year, I took a break from study to figure out what path of learning I wanted to do next. Given I work as an AWS Cloud Engineer, I thought the AWS DevOps Professional certification would be highly relevant as well as an awesome opportunity to learn some new concepts and technology.

![Proof!!](/media/record-of-completion.png)

[This blog](https://medium.com/@apzuk3/what-it-takes-to-pass-the-aws-certified-devops-engineer-professional-exam-40453cf0e3d4) is a really good starting point (I think) to what needs to be learnt/studied for this certification. I love Infrastructure as Code, and this post recommended doing the A Cloud Guru - Advanced AWS CloudFormation course to brush up on CloudFormation skills.

I loved this course. It posed some business challenge case studies, in two fictitious companies. This made the learning much more realistic. 

The course content provides the templates to be deployed. For the first case-study, I re-wrote this, iterating on it as the course progressed. This meant that I got hands-on experience writing the CFN templates, and importantly experienced all of the troubleshooting that comes along with doing so.

For those who are unfamiliar, Infrastructure as Code is a way of declaring in a text file (of some kind), the infrastructure resources, as well their configuration, that you desire to be created. There are many different libraries, frameworks and services to do so. For AWS, [CloudFormation](https://aws.amazon.com/cloudformation/) is the native service that they provide to manage this. Some of the advantages of this service over its competitors is the easy integration into your AWS account, ease of learning/setup, as well as a slight security win (looking at you Terraform with your plain-text state-files!).

Some really cool concepts are taught in this, one of my favourites is how [cfn-hup](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-hup.html) is explained, as this is something that always seems confusing to me. Being able to have EC2 resources detect changes in its own meta-data and run some specified commands is really cool. Tying this to re-implement the cfn-init process after a change is detected is a powerful mechanism for triggering reloading of instance setup command when a stack is updated.

The course was, I believe, recorded around 2017/18, so some of the screens in the console are a little out-of-date, although had changed dramatically since then. At one point, we are required to create some Google web authentication credentials to use in an app we create. The steps around this had changes slightly, but the accompanying instructions from ACG helped to navigate these changes.

Another area of learning in this course, that piqued my interest, was CloudFormation custom resources using Lambda. I've known about this feature of CFN for some time, and the idea had always interested me. Adrian teaches this content in a very simple manner, especially how the resource lifecycle works using the resource properties/attributes and what the functions' responses need to contain for it to all work. From these small and simple demos, we automatically allocated CIDR ranges for a multi-environment application within a VPC, a task that normally would require networking knowledge and manual entry. Through this example, Adrian showed the awesome power of extending CloudFormation using Lambda-based custom resources.

![Custom Resources Slide](/media/custom-resources-lambda-slide.png)

Overall, the design/architecture pattern implemented could be used as the foundations for your own projects, etc. even in a work/production setting. Definitely templates that I'll be hanging onto for some time!!!

#### Amazon Linux 1 AMI Usage and Upgrade Issue:
* Only one real issue (other than superficial issues related to POC nature of apps/environments). The EC2 instances used in the templates were based off of the [Amazon Linux 1 AMI](https://aws.amazon.com/amazon-linux-ami/). Given [this image type is flagged for End-Of-Life at the end of 2020](https://aws.amazon.com/blogs/aws/update-on-amazon-linux-ami-end-of-life/) this is somewhat problematic. For the first case-study, I updated the template(s) to use Amazon Linux 2, which proved difficult. The cfn-init config packages command has difficulty installing an appropriate version of PHP for WordPress to run when the yum 'php' package is used. If the default packages are used, the following error occurs in WordPress: \
\
_**"Your server is running PHP version 5.4.16 but WordPress 5.2 requires at least 5.6.20."**_ \
\
To overcome this, we need to install PHP > v7.2 using the amazon-linux-extras. Unfortunately, this isn't available in the cfn-init configuration packages section. To get this to install, I had to the following command to my install_wordpress configuration:  \

{% highlight yaml %}
commands:
    enable_php:
        cwd: "~"
        command: "amazon-linux-extras install php7.2"
{% endhighlight %} 
\
In any case, that seemed to be one of the only issues when upgrading the instance to Amazon Linux 2. 

### Overall
Pretty stoked to get through this. As with any Infrastructure course, the time taken to get through the content if you do the demos yourself is always a lot longer than the course length, with lots of waiting for stacks to provision/update/delete. Great starting point to move to automation in an AWS native way!


