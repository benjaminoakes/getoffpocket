---
layout: post
title: "Saying Goodbye to Pocket? How to Secure Your 'Read It Later' List with Open Source"
date: 2025-06-16
categories: [tutorial, open-source, data-migration]
tags: [pocket, wallabag, data-export, self-hosting]
excerpt: "With Pocket's recent announcement, users are looking for a more permanent, secure home for their 'read it later' lists. Learn how to migrate to Wallabag, an open-source alternative."
---

## TL;DR / Checklist

- Export your data from Pocket
{% include utm_param.html page_url=include.page_url %}
{% assign pocket_to_wallabag_url = 'https://benjaminoakes.github.io/pocket-to-wallabag/' %}
{% assign pocket_to_wallabag_url_with_referral = pocket_to_wallabag_url | append: utm_and_rby %}
- [Convert your Pocket export for Wallabag]({{ pocket_to_wallabag_url_with_referral }}){: .important-link }
- Choose a hosted Wallabag provider
- Import your data into Wallabag
- Enjoy secure, open-source reading!

---

## You have valuable data in Pocket

For years, Pocket has been a beloved tool for saving articles, videos, and stories. However, with the recent announcement of its shutdown, users are looking for a more permanent, secure home for their "read it later" lists. It's the perfect time to consider an open-source alternative like Wallabag.

{% include content_image_columns.html
  content="This guide will walk you through migrating from Pocket to a hosted Wallabag instance, ensuring your data remains safe, accessible, and under your control."
  src="/assets/images/blog/get-off-pocket/pocket_main.png"
  alt="Pocket Main Interface"
  caption="Pocket's familiar interface that many users have come to love"
  content_class="is-half"
  image_class="is-half"
%}

## Open Source is Your Data's Best Friend

{% include content_image_columns.html
  content="When a service like Pocket shuts down, your data can be lost forever. Open-source software is different. Because the code is public, you can host it yourself or choose from various providers. If one provider goes down, you can simply move your data to another. This means your data is never locked into a single service, giving you the ultimate protection against service closures."
  alt="Open Source Benefits"
  caption="Open source gives you control and flexibility with your data"
  reverse=true
  content_class="is-half"
  image_class="is-half"
%}

## Step-by-Step Guide to Migrating from Pocket to Wallabag

### Step 1: Export Your Pocket Data

First, you'll need to download all of your data from Pocket.

{% include content_image_columns.html
  content="Log in to your Pocket account and go to the export page at
  [getpocket.com/export](https://getpocket.com/export){: .important-link }.
  Click the \"Export CSV file\" link."
  src="/assets/images/blog/get-off-pocket/pocket_export_page.png"
  alt="Pocket Export Page"
  caption="The Pocket export page where you can request your data"
  content_class="is-half"
  image_class="is-half"
%}

{% include content_image_columns.html
  content="Pocket will begin processing your request. This can take some time (up to 7 days, according to their page)."
  src="/assets/images/blog/get-off-pocket/pocket_export_confirmation.png"
  alt="Pocket Export Confirmation"
  caption="Confirmation screen after requesting your data export"
  reverse=true
  content_class="is-half"
  image_class="is-half"
%}

{% include content_image_columns.html
  content="You will receive an email with a link to download your data. Save the file to your computer."
  src="/assets/images/blog/get-off-pocket/pocket_export_email.png"
  alt="Pocket Export Email"
  caption="The email notification with your download link"
  content_class="is-half"
  image_class="is-half"
%}

### Step 2: Convert Your Pocket Export for Wallabag

Your Wallabag server may not directly import Pocket's export format. Luckily, a community-made tool makes conversion simple.

{% assign pocket_to_wallabag_url = 'https://benjaminoakes.github.io/pocket-to-wallabag/' %}
{% assign pocket_to_wallabag_url_with_referral = pocket_to_wallabag_url | append: utm_and_rby %}
{% assign pocket_to_wallabag_referral_link = "Go to the [Pocket to Wallabag Converter](" | append: pocket_to_wallabag_url_with_referral | append: "){: .important-link }." %}
{% include content_image_columns.html
  content=pocket_to_wallabag_referral_link
  src="/assets/images/blog/get-off-pocket/pocket_to_wallabag_converter.png"
  alt="Pocket to Wallabag Converter"
  caption="The web-based converter tool that transforms Pocket exports to Wallabag format"
  content_class="is-half"
  image_class="is-half"
%}

{% include content_image_columns.html
  content="Drag and drop the export file you downloaded from Pocket onto the page. The tool will automatically convert it to a Wallabag-compatible \"Instapaper\" format and download it."
  alt="Conversion Process"
  caption="The conversion process is quick and straightforward"
  reverse=true
  content_class="is-half"
  image_class="is-half"
%}

### Step 3: Choose a Hosted Wallabag Provider

{% assign wallabag_url = 'https://getoffpocket.com/open-source/wallabag/' %}
{% assign wallabag_url_with_referral = wallabag_url | append: utm_and_rby %}
{% assign wallabag_referral_link = "There are several hosted Wallabag providers to choose from. You can find a [list of trusted providers on getoffpocket.com](" | append: wallabag_url_with_referral | append: "){: .important-link } . After you sign up for one, log into your new Wallabag account." %}
{% include content_image_columns.html
  content=wallabag_referral_link
  src="/assets/images/blog/get-off-pocket/wallabag_main.png"
  alt="Wallabag Main Interface"
  caption="Wallabag's clean, modern interface"
  content_class="is-half"
  image_class="is-half"
  reverse=true
%}

### Step 4: Import Your Data into Wallabag

Finally, it's time to import your converted file.

{% include content_image_columns.html
  content="In your Wallabag account, open the menu and click Import. On the next screen, select Instapaper as the source."
  src="/assets/images/blog/get-off-pocket/wallabag_import.png"
  alt="Wallabag Import Screen"
  caption="The import interface in Wallabag where you can upload your converted data"
  content_class="is-half"
  image_class="is-half"
%}

{% include content_image_columns.html
  content="Click the \"FILE\" button and select the converted file from Step 2, then click \"UPLOAD FILE\". Wallabag will begin importing your articles. This may take some time depending on the size of your library."
  alt="Import in Progress"
  caption="Wallabag will process your import in the background"
  reverse=true
  content_class="is-half"
  image_class="is-half"
%}

## Your Data Is Now Safe and Secure

That's it! You've successfully migrated your "read it later" list to a secure, open-source platform. Now, you can enjoy all the features you loved about Pocket, with the added peace of mind that comes from knowing your data is truly yours. With Wallabag, you're not just a user—you're in control.
