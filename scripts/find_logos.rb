# frozen_string_literal: true

# ------------------------------------------------------------------------------
# Ruby Logo Finder
#
# Description:
#   This script attempts to find the official logo URL for a given list of
#   products or companies. It works by scraping the company's homepage and
#   intelligently searching for image URLs that are likely to be the logo.
#
# Dependencies:
#   This script requires the 'nokogiri' gem for HTML parsing.
#   Install it by running:
#   gem install nokogiri
#
# How to Run:
#   Save this file (e.g., as logo_finder.rb) and run it from your terminal:
#   ruby logo_finder.rb
#
# ------------------------------------------------------------------------------

require 'net/http'
require 'uri'
require 'nokogiri'
require 'openssl' # Required for HTTPS

# --- Configuration ---
# A hash where keys are product names and values are their homepages.
# We start with the homepage as it's the most likely place to find a logo.
PRODUCT_URLS = {
  "Instapaper" => "https://www.instapaper.com",
  "Pocket" => "https://getpocket.com",
  "Raindrop.io" => "https://raindrop.io",
  "Safari Reading List" => "https://www.apple.com", # Feature of Apple Safari
  "EmailThis" => "https://www.emailthis.me",
  "Matter" => "https://hq.getmatter.app",
  "Microsoft OneNote" => "https://www.onenote.com",
  "Omnivore" => "https://omnivore.app",
  "Readwise Reader" => "https://readwise.io/reader",
  "Reeder" => "https://reederapp.com",
  "Goodlinks" => "https://goodlinks.app",
  "Wallabag" => "https://wallabag.org",
  "Linkding" => "https://github.com/sissbruecker/linkding", # GitHub page is primary
  "Readeck" => "https://www.readeck.com",
  "LinkWarden" => "https://linkwarden.app",
  "Diigo" => "https://www.diigo.com",
  "Linkora" => "https://linkora.xyz",
  "Evernote" => "https://evernote.com",
  "PaperSpan" => "https://www.paperspan.com",
  "Readability" => "https://www.engadget.com/2016-09-15-readability-is-shutting-down.html", # Defunct, find logo on tribute
  "Amazon Kindle" => "https://www.amazon.com/kindle",
  "BitRead" => "https://bitread.net",
  "Bublup" => "https://www.bublup.com",
  "MarkMark" => "https://markmark.app"
}.freeze

# --- Core Logic ---

# Fetches the HTTP response for a given URL.
# Handles redirects and uses SSL for HTTPS.
def fetch_response(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  # Use a reasonable timeout
  http.open_timeout = 5
  http.read_timeout = 5

  request = Net::HTTP::Get.new(uri.request_uri, { 'User-Agent' => 'LogoFinder-Ruby-Script/1.0' })
  response = http.request(request)

  # Handle redirects
  if response.is_a?(Net::HTTPRedirection) && response['location']
    new_uri = URI.join(uri, response['location'])
    return fetch_response(new_uri) # Recursive call to follow redirect
  end

  response
rescue StandardError => e
  puts "  └─ [Error] Failed to fetch #{uri}: #{e.message}"
  nil
end


# Converts a relative URL (e.g., "/images/logo.png") to an absolute URL.
def make_absolute_url(base_uri, path)
  return nil if path.nil? || path.strip.empty?
  # If path already is absolute, just parse it. Otherwise, join with base.
  URI.join(base_uri, path.strip)
rescue URI::InvalidURIError
  nil
end

# Checks if a URL points to a valid, accessible image.
def is_valid_image_url?(uri)
  return false unless uri
  response = fetch_response(uri)
  response&.is_a?(Net::HTTPSuccess) && response.content_type&.start_with?('image/')
end

# The main class responsible for finding a logo on a webpage.
class LogoFinder
  def initialize(product_name, base_url)
    @product_name = product_name
    @base_uri = URI.parse(base_url)
    @doc = nil
  end

  # Main method to find the logo.
  def find_logo
    puts "🔍 Searching for '#{@product_name}' logo at #{@base_uri}..."
    response = fetch_response(@base_uri)
    return "[Error] Could not fetch page." unless response&.is_a?(Net::HTTPSuccess)

    @doc = Nokogiri::HTML(response.body)

    # Search for the logo using a prioritized list of strategies.
    logo_url = find_by_apple_icon ||
               find_by_svg_logo ||
               find_in_meta_tags ||
               find_in_img_tags ||
               find_by_favicon

    if logo_url
      puts "  └─ ✅ Found: #{logo_url}"
      logo_url.to_s
    else
      puts "  └─ ❌ Not Found"
      "Not Found"
    end
  end

  private

  # Strategy 1: Look for Apple touch icons (often high-res).
  def find_by_apple_icon
    find_link_tag(%q(link[rel="apple-touch-icon"], link[rel="apple-touch-icon-precomposed"]))
  end

  # Strategy 2: Look for SVG elements that are likely logos.
  def find_by_svg_logo
    # This is a heuristic. We look for SVGs that are explicitly labeled as logos.
    svg = @doc.at_css('a[href="/"] svg, header svg, [class*="logo"] svg')
    return nil unless svg

    # If the SVG is simple, we can't do much. This is a placeholder for more complex logic.
    # In a real-world scenario, you might try to serialize the SVG data.
    # For now, we prefer linked images.
    puts "  ├─ [Info] Found an inline SVG logo, but prefer linked images."
    nil
  end

  # Strategy 3: Look in <meta> tags (e.g., og:image).
  def find_in_meta_tags
    meta_tag = @doc.at_css('meta[property="og:image"], meta[property="twitter:image"]')
    return nil unless meta_tag && meta_tag['content']

    url = make_absolute_url(@base_uri, meta_tag['content'])
    is_valid_image_url?(url) ? url : nil
  end


  # Strategy 4: Look for <img> tags with "logo" in src, alt, or class.
  def find_in_img_tags
    # This XPath looks for an <img> tag inside a link to the homepage, which is a strong signal.
    # It also checks for "logo" in various attributes as a fallback.
    xpath_query = %q(//a[@href='/']//img | //img[contains(@src, 'logo')] | //img[contains(@alt, 'logo') or contains(@alt, 'Logo')] | //img[contains(@class, 'logo')])
    img = @doc.xpath(xpath_query).first
    return nil unless img && img['src']

    url = make_absolute_url(@base_uri, img['src'])
    is_valid_image_url?(url) ? url : nil
  end

  # Strategy 5: Fallback to the standard favicon.
  def find_by_favicon
    find_link_tag(%q(link[rel="icon"], link[rel="shortcut icon"]))
  end
  
  # Helper to find a logo in <link> tags based on a CSS selector.
  def find_link_tag(selector)
    link = @doc.at_css(selector)
    return nil unless link && link['href']

    url = make_absolute_url(@base_uri, link['href'])
    is_valid_image_url?(url) ? url : nil
  end

end

# --- Execution ---

def main
  puts "--- Starting Logo Search ---"
  results = {}

  PRODUCT_URLS.each do |product, url|
    finder = LogoFinder.new(product, url)
    results[product] = finder.find_logo
    puts "-" * 20 # Separator
  end

  puts "\n\n--- Final Results ---"
  PRODUCT_URLS.keys.each do |product|
    printf "%-25s %s\n", product, results[product]
  end
  puts "--- End of Report ---"
end

# Run the main function when the script is executed.
if __FILE__ == $0
  main
end

