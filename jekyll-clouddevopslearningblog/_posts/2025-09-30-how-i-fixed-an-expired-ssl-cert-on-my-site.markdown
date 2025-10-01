---
layout: post
title: "How I Fixed an Expired SSL Certificate on My S3 + CloudFront Static Site"
date: 2025-09-30 00:00:00 +1000
categories: aws cloudfront s3 devops troubleshooting
---

When I first built [theclouddevopslearningblog.com](https://theclouddevopslearningblog.com), I chose one of the most common ways to host a static website on AWS:

- A **Jekyll site** stored in an **S3 bucket**
- Served through **CloudFront** as a CDN and to support **HTTPS**
- A **free SSL certificate** from **AWS Certificate Manager (ACM)**

It worked perfectly… until one day, my site suddenly started showing security warnings, and browsers said the connection was “**Not Secure**.” 

Here’s how I diagnosed the problem and fixed it — and how you can do the same if it happens to you.

---

## Step 1: Spot the Problem

The first sign something was wrong was when I tried to run a simple test:

```bash
curl -I https://theclouddevopslearningblog.com
```

This gave me:

```
curl: (60) SSL certificate problem: certificate has expired
```

This error means the certificate that encrypts traffic to my site was no longer valid — so HTTPS wasn’t working.

---

## Step 2: Check What Certificate Is Being Used

To see exactly what certificate CloudFront was serving, I used `openssl`:

```bash
openssl s_client -servername theclouddevopslearningblog.com   -connect theclouddevopslearningblog.com:443 -showcerts </dev/null 2>/dev/null   | openssl x509 -noout -issuer -subject -dates -ext subjectAltName
```

The output showed this:

```
issuer=C=US, O=Amazon, CN=Amazon RSA 2048 M02
subject=CN=theclouddevopslearningblog.com
notBefore=Mar 10 00:00:00 2024 GMT
notAfter=Apr  8 23:59:59 2025 GMT
```

The important part is `notAfter` — the certificate expired on **April 8, 2025**. Mystery solved!

---

## Step 3: Why Didn’t It Renew Automatically?

Certificates from ACM usually renew automatically, but **only if the DNS validation records are still in place**.  
When I checked the certificate in the **ACM console (in `us-east-1`)**, I saw that:

- The certificate had **expired**
- Renewal **failed** because the DNS validation records had been deleted

This is a very common mistake — if you remove the validation CNAME records after issuing the certificate, AWS can’t confirm you still own the domain. And without that, it won’t renew.

---

## Step 4: Request a New Certificate

The fix was simple:

1. Go to **ACM → Request a public certificate**
2. Add both:
   - `theclouddevopslearningblog.com`
   - `*.theclouddevopslearningblog.com`
3. Choose **DNS validation**
4. Add the CNAME records ACM gives you into your DNS (for example, in Route 53)
5. Wait until the certificate status changes to **“Issued”**

⚠️ **Tip:** Leave those DNS CNAMEs in place forever. They’re needed for future renewals too.

---

## Step 5: Attach the New Certificate in CloudFront

Just creating the new certificate isn’t enough — CloudFront still needs to know to use it.

Here’s how:

- Go to **CloudFront → Distributions → [your distribution]**
- Under **Alternate domain names (CNAMEs)**, make sure your domain is listed
- Under **Viewer certificate**, choose **“Custom SSL certificate”** and select the new one
- Save your changes

This will trigger a new deployment, which usually takes a few minutes.

---

## Step 6: Test Again

After the update finished, I tested again:

```bash
curl -I https://theclouddevopslearningblog.com
```

Now I got:

```
HTTP/2 200
server: CloudFront
```

And `openssl` showed the new certificate expiry date was in **2026**.

---

## Lessons Learned

This was a small problem, but it taught me a few useful lessons that are worth sharing:

1. **Leave DNS validation records in place.** They’re essential for automatic renewal.
2. **Set a renewal alert.** You can use EventBridge + SNS to send yourself an email before a certificate expires.
3. **Remember the region.** CloudFront only works with ACM certificates in `us-east-1`.
4. **Add monitoring.** A simple `curl` script in a cron job can catch certificate problems before users do.

---

## Final Thoughts

Static sites on S3 + CloudFront are incredibly powerful and cost-effective, but even “serverless” websites need a little maintenance. SSL certificates are one of those things you *don’t* want to ignore — and now I’ll never forget to keep an eye on mine!

Hopefully, this guide helps you fix an expired certificate quickly and with confidence. 

---

*Have you run into similar CloudFront issues? Let me know — I might write a follow-up post on automating SSL monitoring!*
