---
layout: post
title:  "Cloud Guru Challenge - October 2020"
date:   2020-11-16 14:15:00 +1000
categories: aws sagemaker
tags: aws sagemaker acloudguru python jupyter machine-learning recommendation imdb open-data
---
## Cloud Guru Challenge - October 2020

![Image Titel](/media/imagetitle.png)

## Background
https://acloudguru.com/blog/engineering/cloudguruchallenge-machine-learning-on-aws

## Steps

1. Determine use case and obtain data.

   The first decision to make was to do with what data to use. In the brief, Kesha Williams made the example suggestion of movie datasets from IMDB.
   
   I thought about using GoodReads data to build a book recommendation engine, moreso because it would be a point of differentiation. However, my interests align with TV and film more than literature, so I decided the IMDB datasets will be a better fit for me.
   
   The datasets are all available for download here: https://datasets.imdbws.com/
   
   The recommended sets to use by Kesha were the title.akas (for grouping alternate titles' info), title.basics (basic information about the titles) and title.ratings (rating information for the titles)
   
   I used the 'requests' python library to download these.
   
2. Create Jupyter hosted notebook
   
   My experience with Jupyter is pretty minimal. I'd played with it very briefly when doing a AWS DeepRacer lab over a year ago now. I wanted to get a good understanding of how Jupyter works, so I did the following course on A Cloud Guru: https://learn.acloud.guru/course/introduction-to-jupyter-notebooks
   
   I installed Jupyter on my local machine to begin with and learn about how the notebooks work.

   A really cool advantage of Jupyter notebooks is the reproducable nature of the runs, meaning anyone can run the same experiment, even when the underlying data changes.
   
   The course was a very interesting introduction to some of the good data science tools that are available in Python, as well as how to use hosted notebooks in the cloud.

   The real advantage of this is that you can perform data science experiments and ML training using resources that you normally wouldn't have access to, and only need to pay for the infrastructure as you use it!
   
   Infrastructure as Code: Spinning up a Sagemaker Jupyter notebook using CloudFormation was relatively straightforward using https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sagemaker-notebookinstance.html
   
   Here's the template I used to spin up the instance:
   
   {% highlight yaml %}
    ____________
   {% endhighlight %}


## Datasets