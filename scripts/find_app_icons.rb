# frozen_string_literal: true

# ------------------------------------------------------------------------------
# Ruby App Icon Finder
#
# Description:
#   This script finds official icons for a list of products. It prioritizes
#   searching the Apple App Store and Google Play Store, falling back to
#   scraping the product's homepage if the app is not found in the stores.
#
# Dependencies:
#   - nokogiri: gem install nokogiri
#   - json: (standard library)
#
# How to Run:
#   Save this file (e.g., as app_icon_finder.rb) and run it from your terminal:
#   ruby app_icon_finder.rb
#
# ------------------------------------------------------------------------------

require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'
require 'openssl'
require 'cgi' # For URL encoding search terms

# --- Configuration ---
# This list is the same as before. The script will find the best icon source.
PRODUCT_URLS = {
  "Instapaper" => "https://www.instapaper.com",
  "Pocket" => "https://getpocket.com",
  "Raindrop.io" => "https://raindrop.io",
  "Safari Reading List" => "https://www.apple.com/safari/",
  "EmailThis" => "https://www.emailthis.me",
  "Matter" => "https://hq.getmatter.app",
  "Microsoft OneNote" => "https://www.onenote.com",
  "Omnivore" => "https://omnivore.app",
  "Readwise Reader" => "https://readwise.io/reader",
  "Reeder" => "https://reederapp.com",
  "Goodlinks" => "https://goodlinks.app",
  "Wallabag" => "https://wallabag.org",
  "Linkding" => "https://github.com/sissbruecker/linkding",
  "Readeck" => "https://www.readeck.com",
  "LinkWarden" => "https://linkwarden.app",
  "Diigo" => "https://www.diigo.com",
  "Linkora" => "https://linkora.xyz",
  "Evernote" => "https://evernote.com",
  "PaperSpan" => "https://www.paperspan.com",
  "Readability" => "https://www.engadget.com/2016-09-15-readability-is-shutting-down.html",
  "Amazon Kindle" => "https://www.amazon.com/kindle",
  "BitRead" => "https://bitread.net",
  "Bublup" => "https://www.bublup.com",
  "MarkMark" => "https://markmark.app"
}.freeze

# --- Shared Helper Functions ---

# Fetches an HTTP response, handling redirects and setting a user agent.
def fetch_response(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.open_timeout = 10
  http.read_timeout = 10
  
  request = Net::HTTP::Get.new(uri.request_uri, { 'User-Agent' => 'AppIconFinder-Ruby-Script/1.0' })
  response = http.request(request)

  if response.is_a?(Net::HTTPRedirection) && response['location']
    new_uri = URI.join(uri, response['location'])
    return fetch_response(new_uri)
  end
  response
rescue StandardError => e
  puts "    └─ [Error] Failed to fetch #{uri}: #{e.message}"
  nil
end

# --- App Store Search Logic ---

# Searches the Apple App Store using the iTunes Search API.
def search_apple_app_store(term)
  puts "  ├─ Searching Apple App Store for '#{term}'..."
  # The API endpoint for searching. We limit to 'software' and a single result.
  encoded_term = CGI.escape(term)
  api_uri = URI("https://itunes.apple.com/search?term=#{encoded_term}&entity=software&limit=1")
  
  response = fetch_response(api_uri)
  return nil unless response&.is_a?(Net::HTTPSuccess)

  data = JSON.parse(response.body)
  return nil if data['resultCount'] == 0

  # Get the highest resolution artwork available.
  icon_url = data['results'][0]['artworkUrl512']
  icon_url ? { url: icon_url, source: 'Apple App Store' } : nil
end

# Searches the Google Play Store by scraping the search results page.
def search_google_play_store(term)
  puts "  ├─ Searching Google Play Store for '#{term}'..."
  encoded_term = CGI.escape(term)
  search_uri = URI("https://play.google.com/store/search?q=#{encoded_term}&c=apps")

  response = fetch_response(search_uri)
  return nil unless response&.is_a?(Net::HTTPSuccess)

  doc = Nokogiri::HTML(response.body)
  # The selector for the first app icon in the search results.
  # Note: These selectors can be brittle and may change if Google updates their site.
  icon_element = doc.at_css('div[role="listitem"] img')
  return nil unless icon_element && icon_element['src']
  
  { url: icon_element['src'], source: 'Google Play Store' }
end


# --- Website Fallback Logic (Adapted from previous script) ---
class WebsiteLogoFinder
  def initialize(base_uri)
    @base_uri = base_uri
    @doc = nil
  end

  def find_logo
    puts "  ├─ Falling back to website scrape: #{@base_uri}"
    response = fetch_response(@base_uri)
    return nil unless response&.is_a?(Net::HTTPSuccess)

    @doc = Nokogiri::HTML(response.body)
    
    # Try various strategies to find a logo on the page.
    url = find_link_tag('link[rel="apple-touch-icon"]') ||
          find_in_meta_tags ||
          find_in_img_tags ||
          find_link_tag('link[rel="icon"]')
          
    url ? { url: url.to_s, source: 'Website' } : nil
  end
  
  private

  def make_absolute_url(path)
    URI.join(@base_uri, path.strip) rescue nil
  end

  def find_link_tag(selector)
    link = @doc.at_css(selector)
    link ? make_absolute_url(link['href']) : nil
  end

  def find_in_meta_tags
    meta = @doc.at_css('meta[property="og:image"]')
    meta ? make_absolute_url(meta['content']) : nil
  end

  def find_in_img_tags
    img = @doc.at_css('header img, [class*="logo"] img')
    img ? make_absolute_url(img['src']) : nil
  end
end

# --- Main Orchestration ---
def main
  puts "--- Starting App Icon Search ---"
  results = {}

  PRODUCT_URLS.each do |product, url|
    puts "🔍 Searching for '#{product}'..."
    
    # The search strategy: App Store -> Google Play -> Website
    result = search_apple_app_store(product) ||
             search_google_play_store(product) ||
             WebsiteLogoFinder.new(URI.parse(url)).find_logo

    if result
      puts "  └─ ✅ Found on #{result[:source]}: #{result[:url]}"
      results[product] = result[:url]
    else
      puts "  └─ ❌ Not Found on any platform."
      results[product] = "Not Found"
    end
    puts "-" * 20
  end

  puts "\n\n--- Final Results ---"
  PRODUCT_URLS.keys.each do |product|
    printf "%-25s %s\n", product, results[product]
  end
  puts "--- End of Report ---"
end

if __FILE__ == $0
  main
end
