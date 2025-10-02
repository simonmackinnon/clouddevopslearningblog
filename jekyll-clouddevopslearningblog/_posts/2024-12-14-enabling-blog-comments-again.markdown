---
layout: post
title:  "Enabling Blog Comments (Again)"
date:   2024-12-14 00:00:00 +1000
categories: blog jekyll
tags: blog comments jekyll aws cloudfront s3
---

# Enabling Blog Comments (Again)

It's been a while between drinks hey? 

When I created this blog, I initially used the default support for Disqus as the blog commenting capability. After a few issues with the privacy, etc., I switched to a free trial of an alternative, HyvorTalk. This worked fine, but after the free trial, my comments got disabled, and I hadn't focused on this, until the last few days.

I moved the comments back to Disqus. However, I haven't maintained this blog for about 4-5 years, so making changes was problematic.

In fact, I'd hardly used my personal development machine in about that time too, so there were a few things that were broken:

* Jekyll wouldn't run because my Ruby version was out of date
* Homebrew wouldn't re-install Ruby because it was out of date

So after a complete re-install of Homebrew, Ruby and Jekyll, I was able to get Jekyll running. The next issue was that the gem bundler wouldn't run with various issues. I was able to get it running by deleting the Gemfile.lock and changing the theme / gem back to the default. However, I was still getting errors with undefined methods, etc. when trying to serve the site. My solution was to re-initialise the Jekyll site, update the parameters needed for the theme to work, and copy the posts acrosss. This got it working fine.

At this point, I was able to get the Disqus comments section added again via the default support (I'd played around with the code for this to enable HyvorTalk previously, so had to wipe that code). I was able to build and run the site locally and get the comments section to load. However, after I built the site, I pushed it to my static site S3 bucket. After I loaded the posts again, I wasn't getting it loading. After a while playing around with the site files, I realised I was being served different files than I uploaded. Having not looked at my site for several years, I'd completely forgotten that I had put a CDN (CloudFront) in front of the site (mainly to get https working). After pushing a '/*' invalidation to the distribution, the site was serving up the right content (dull yay).

So, what's next? I'm going to be trying to post a bit more of some of the stuff I'm working on and learning, and maybe a refresh of the site altogether at some point.