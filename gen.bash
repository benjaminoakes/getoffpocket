#!/bin/bash

# This script automates the creation of the get-started collection,
# layouts, and product pages for the getoffpocket.com Jekyll site.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Creating layouts for the 'get-started' pages..."

# Create the _layouts directory if it doesn't exist
mkdir -p _layouts

# Create the get_started_index.html layout
cat << 'EOF' > _layouts/get_started_index.html
---
layout: default
---
{%- assign product = site.data.products | where: "key", page.product_key | first -%}
<div class="container section">
  <div class="has-text-centered">
    <h1 class="title is-1">{{ product.name }} is an open source service</h1>
    <div class="py-4">
      <h4 class="title is-4">What is your comfort level with tech?</h4>
      <div class="buttons is-centered">
        <a href="/get-started/{{ product.key }}/managed-hosting/" class="button is-primary is-medium">I just want to use the app</a>
        <a href="/get-started/{{ product.key }}/self-hosted/" class="button is-link is-medium">I want to self-host this service</a>
      </div>
    </div>
  </div>
</div>
EOF

# Create the get_started_managed-hosting.html layout
cat << 'EOF' > _layouts/get_started_managed-hosting.html
---
layout: default
---
{%- assign product = site.data.products | where: "key", page.product_key | first -%}
<div class="container section">
  <div class="has-text-centered">
    <h1 class="title is-1">Use {{ product.name }} Like Any Other App</h1>
    <h5 class="title is-5 has-text-centered">Choose your provider.</h5>
    <div class="content">
      <p>For a small monthly fee, you will get access to this service. Your chosen provider will handle the rest.</p>
      <p>Support an independent software developer and help "small tech" grow.</p>
    </div>
    <div class="mt-5">
        <a href="/get-started/{{ product.key }}/" class="button is-info">&larr; Go Back</a>
    </div>
  </div>
</div>
EOF

# Create the get_started_self-hosted.html layout
cat << 'EOF' > _layouts/get_started_self-hosted.html
---
layout: default
---
{%- assign product = site.data.products | where: "key", page.product_key | first -%}
<div class="container section">
  <div class="has-text-centered">
      <h1 class="title is-1">Self-Host {{ product.name }}</h1>
      <h5 class="title is-5">You can self-host this project. Here are some options:</h5>
      <p class="help">If you would like, purchase through these links to support <a href="/">getoffpocket.com</a>. You can also <a href="{{ site.donate_url }}">donate any amount</a> to support us directly. We aim to be good citizens and contribute 10% of any profits to these open source projects.</p>
  </div>

  <div class="content has-text-left mt-4 pt-4" style="max-width: 480px; margin: 1.5rem auto 0; border-top: 1px solid #dbdbdb;">
    <ul>
      <li style="margin-bottom: 1.5rem;">
        <strong><a href="{{ site.digital_ocean_referral_url }}" target="_blank" rel="noopener noreferrer">Host on Digital Ocean</a></strong>
        <p class="has-text-grey-dark">Get $200 in credit over 60 days to run this service and other projects.</p>
      </li>
      <li style="margin-bottom: 1.5rem;">
        <strong><a href="https://www.amazon.com/CanaKit-Raspberry-Starter-Kit-PRO/dp/B0CRSNCJ6Y" target="_blank" rel="noopener noreferrer">Run on a Raspberry Pi</a></strong>
        <p class="has-text-grey-dark">A low-cost, energy-efficient option for home hosting.</p>
      </li>
      <li>
        <strong><a href="{{ product.github_url }}" target="_blank" rel="noopener noreferrer">View Source Code</a></strong>
        <p class="has-text-grey-dark">For self-hosting on your own existing infrastructure.  Free, if you already have the hardware, time, and skills to host it.</p>
      </li>
    </ul>
  </div>

  <div class="has-text-centered mt-5">
      <a href="/get-started/{{ product.key }}/" class="button is-info">&larr; Go Back</a>
  </div>
</div>
EOF

echo "Layouts created successfully."
echo "Creating the '_get_started' collection and product pages..."

# Create the _get_started directory if it doesn't exist
mkdir -p _get_started

# An array of product keys to create pages for
products=("wallabag" "readeck" "sunya-folio")

# Loop through the products and create the necessary files
for product_key in "${products[@]}"
do
  echo "Creating pages for $product_key..."
  mkdir -p "_get_started/$product_key"

  # Create the index.md file with the permalink override
  cat << EOF > "_get_started/$product_key/index.md"
---
layout: get_started_index
product_key: $product_key
permalink: /get-started/$product_key/
---
EOF

  # Create the managed-hosting.md file
  cat << EOF > "_get_started/$product_key/managed-hosting.md"
---
layout: get_started_managed-hosting
product_key: $product_key
---
EOF

  # Create the self-hosted.md file
  cat << EOF > "_get_started/$product_key/self-hosted.md"
---
layout: get_started_self-hosted
product_key: $product_key
---
EOF
done

echo "Collection pages created successfully."
echo ""
echo "------------------------------------------------------------------------"
echo "ACTION REQUIRED: Please manually update your '_config.yml' file."
echo "Add the following under the 'collections' key:"
echo ""
echo "  get_started:"
echo "    output: true"
echo "    permalink: /get-started/:path/"
echo ""
echo "It should look something like this:"
echo "collections:"
echo "  open_source:"
echo "    output: true"
echo "    permalink: /open-source/:name/"
echo "  proprietary:"
echo "    output: true"
echo "    permalink: /proprietary/:name/"
echo "  get_started:"
echo "    output: true"
echo "    permalink: /get-started/:path/"
echo "------------------------------------------------------------------------"
echo ""
echo "Script finished."
