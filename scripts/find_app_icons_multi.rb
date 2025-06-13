# frozen_string_literal: true

# ------------------------------------------------------------------------------
# Ruby Icon Collector
#
# Description:
#   This script aggressively searches for and collects as many official icons
#   as possible for a given list of products. It queries the Apple App Store
#   and Google Play Store for multiple results, and also falls back to
#   scraping the product's homepage. All unique icon URLs are collected.
#
# Dependencies:
#   - nokogiri: gem install nokogiri
#
# How to Run:
#   Save this file (e.g., as icon_collector.rb) and run it from your terminal:
#   ruby icon_collector.rb
#
# ------------------------------------------------------------------------------

require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'
require 'openssl'
require 'cgi'

# --- Configuration ---
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
def fetch_response(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.open_timeout = 10
  http.read_timeout = 10
  
  request = Net::HTTP::Get.new(uri.request_uri, { 'User-Agent' => 'IconCollector-Ruby-Script/1.0' })
  response = http.request(request)

  if response.is_a?(Net::HTTPRedirection) && response['location']
    new_uri = URI.join(uri, response['location'])
    return fetch_response(new_uri)
  end
  response
rescue StandardError => e
  puts "    └─ [Error] Fetch failed for #{uri}: #{e.message}"
  nil
end

# --- Search Logic ---

# Searches the Apple App Store for up to 20 results.
def search_apple_app_store(term)
  puts "  ├─ Searching Apple App Store for '#{term}'..."
  encoded_term = CGI.escape(term)
  # Request more results to get different versions (iPhone, iPad, etc.)
  api_uri = URI("https://itunes.apple.com/search?term=#{encoded_term}&entity=software&limit=20")
  
  response = fetch_response(api_uri)
  return [] unless response&.is_a?(Net::HTTPSuccess)

  data = JSON.parse(response.body)
  return [] if data['resultCount'] == 0

  # Collect all high-resolution artwork URLs from the results.
  data['results'].map { |result| result['artworkUrl512'] }.compact
end

# Scrapes the Google Play Store for all icons on the first search page.
def search_google_play_store(term)
  puts "  ├─ Searching Google Play Store for '#{term}'..."
  encoded_term = CGI.escape(term)
  search_uri = URI("https://play.google.com/store/search?q=#{encoded_term}&c=apps")

  response = fetch_response(search_uri)
  return [] unless response&.is_a?(Net::HTTPSuccess)

  doc = Nokogiri::HTML(response.body)
  # This selector finds all app icons in the main search results list.
  # Note: Selectors can be brittle and may change with website updates.
  doc.css('div[role="listitem"] img').map { |img| img['src'] }.compact
end


# Finds a logo on a product's direct website.
class WebsiteLogoFinder
  def initialize(base_uri)
    @base_uri = base_uri
    @doc = nil
  end

  def find_logo
    puts "  ├─ Searching website: #{@base_uri}"
    response = fetch_response(@base_uri)
    return nil unless response&.is_a?(Net::HTTPSuccess)
    @doc = Nokogiri::HTML(response.body)
    
    # Return the first one found from this prioritized list.
    find_link_tag('link[rel="apple-touch-icon"]') ||
    find_in_meta_tags('meta[property="og:image"]') ||
    find_in_img_tags('header img, [class*="logo"] img') ||
    find_link_tag('link[rel="icon"]')
  end
  
  private
  def make_absolute_url(path)
    URI.join(@base_uri, path.strip) rescue nil
  end

  def find_link_tag(selector)
    link = @doc.at_css(selector)
    link ? make_absolute_url(link['href'])&.to_s : nil
  end

  def find_in_meta_tags(selector)
    meta = @doc.at_css(selector)
    meta ? make_absolute_url(meta['content'])&.to_s : nil
  end

  def find_in_img_tags(selector)
    img = @doc.at_css(selector)
    img ? make_absolute_url(img['src'])&.to_s : nil
  end
end

# --- Main Orchestration ---
def main
  puts "--- Starting Aggressive Icon Search ---"
  all_results = {}

  PRODUCT_URLS.each do |product, url|
    puts "🔍 Collecting icons for '#{product}'..."
    collected_icons = []
    
    # 1. Search Apple App Store
    collected_icons.concat(search_apple_app_store(product))
    
    # 2. Search Google Play Store
    collected_icons.concat(search_google_play_store(product))
    
    # 3. Fallback to Website
    website_icon = WebsiteLogoFinder.new(URI.parse(url)).find_logo
    collected_icons << website_icon if website_icon

    # Store the unique, non-nil results
    all_results[product] = collected_icons.compact.uniq
    
    if all_results[product].empty?
      puts "  └─ ❌ No icons found for '#{product}'."
    else
      puts "  └─ ✅ Collected #{all_results[product].count} unique icon(s) for '#{product}'."
    end
    puts "-" * 20
  end

  puts "\n\n--- Final Results: All Collected Icons ---"
  all_results.each do |product, icons|
    puts "\n#{product}:"
    if icons.empty?
      puts "  Not Found"
    else
      icons.each { |icon_url| puts "  - #{icon_url}" }
    end
  end
  puts "\n--- End of Report ---"
end

if __FILE__ == $0
  main
end
