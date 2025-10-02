---
layout: post
title: "Automating Jekyll Builds and S3 Deployments with GitHub Actions"
date: 2025-10-02 00:00:00 +1000
categories: devops aws jekyll ci-cd
description: "How I set up a GitHub Actions workflow to build my Jekyll site and deploy it automatically to an S3 bucket and CloudFront."
---

For a long time, I was manually building my Jekyll blog and pushing the generated `_site` directory up to S3. It worked, but it was slow, error-prone, and easy to forget. So I finally decided to automate the whole thing with **GitHub Actions** — and in this post, I’ll show you how I did it, including the little gotchas that tripped me up along the way.

This walkthrough builds on some great work others have shared — in particular, [this excellent guide from PagerTree](https://pagertree.com/blog/jekyll-site-to-aws-s3-using-github-actions), which I used as my starting point. I’ve adapted and expanded on it here to match my own workflow and highlight some issues I ran into along the way.

---

## 🧰 Why Automate Your Jekyll Deployments?

Every time you push to your main branch, you can have GitHub automatically:

- Install Ruby and your Jekyll dependencies  
- Build your static site  
- Upload the generated files to your S3 bucket  
- Invalidate your CloudFront cache so changes go live immediately  

This turns deployment from a manual multi-step process into a simple **`git push`**.

---

## 🛠️ Setting Up the Workflow

The workflow file lives at `.github/workflows/deploy.yml` in your repo. Here’s a trimmed-down version of mine:

```yaml
name: CI / CD

on:
  push:
    branches: [ master ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: jekyll-clouddevopslearningblog

    steps:
      - uses: actions/checkout@v4

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.2"
          bundler-cache: true

      - name: Ensure Linux platform support
        run: bundle lock --add-platform x86_64-linux

      - name: Build the site
        env:
          JEKYLL_ENV: production
        run: bundle exec jekyll build --trace

      - name: Deploy to S3
        run: aws s3 sync ./_site/ s3://${{ secrets.AWS_S3_BUCKET_NAME }} --delete --acl public-read --cache-control max-age=604800

      - name: Invalidate CloudFront cache
        run: aws cloudfront create-invalidation --distribution-id ${{ secrets.AWS_CLOUDFRONT_DISTRIBUTION_ID }} --paths "/*"
```

---

## 🔐 Configuring Secrets

You’ll need to store a few secrets in your GitHub repository settings (`Settings → Secrets and variables → Actions`):

- `AWS_ACCESS_KEY_ID` – your AWS access key  
- `AWS_SECRET_ACCESS_KEY` – your AWS secret key  
- `AWS_S3_BUCKET_NAME` – the name of your bucket  
- `AWS_CLOUDFRONT_DISTRIBUTION_ID` – the ID of your CloudFront distribution  

These are injected into the workflow automatically and keep sensitive data out of your repo.

---

## 🧩 Common Gotchas (And How I Fixed Them)

I ran into a few issues that are worth mentioning:

### 1. `Could not locate Gemfile or .bundle/ directory`

This happens when the workflow runs in the wrong directory. If your Jekyll site is inside a subfolder (like `jekyll-clouddevopslearningblog`), make sure to set:

```yaml
defaults:
  run:
    working-directory: jekyll-clouddevopslearningblog
```

---

### 2. `bundler: command not found: jekyll`

This one confused me at first — it means Bundler installed your gems, but `jekyll` wasn’t among them. Usually the cause is that you’re not running commands with `bundle exec`, or that Jekyll isn’t listed in your `Gemfile`.

✅ Fix: Make sure your `Gemfile` includes:

```ruby
gem "jekyll", "~> 4.3"
```

And build the site like this:

```yaml
- run: bundle exec jekyll build --trace
```

---

### 3. `You must add the platform x86_64-linux to your lockfile`

If you created your `Gemfile.lock` on macOS, the Linux runner on GitHub Actions won’t install some gems. You can fix this by adding a step before installation:

```yaml
- name: Ensure Linux platform support
  run: bundle lock --add-platform x86_64-linux
```

Commit the updated lockfile once and you can remove this step.

### 4. `You must copy the vendor posts.html to the repo if you've added custom code`

I added some custom code in the post.html of the bundle directly on my machine. So when I used github actions to build the site and deploy, it didn't have these changes. By copying this to the repo version at _includes/post.html, this meant these changes could be added when built remotely

---

## 🚀 Going Further

Some ideas for future improvements:

- Use [OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html) and `aws-actions/configure-aws-credentials` instead of storing long-lived AWS keys.  
- Add a `paths:` filter so the workflow only runs if Jekyll files change.  
- Automate CloudFront invalidations conditionally to save API calls.

---

## 🎉 Final Thoughts

This setup has completely changed my workflow: now I can just commit and push, and within a minute or two, the live site updates automatically. It’s one of those small bits of DevOps automation that pays off quickly — especially if you’re constantly tweaking content or adding new posts.

If you’re still deploying manually, give this a try. Once you see how easy it is, you’ll never want to go back.

---

Have questions or ran into different errors? Drop them in the comments below — I’d love to hear how you’ve set up your own Jekyll CI/CD pipeline!
