# frozen_string_literal: true

# ------------------------------------------------------------------------------
# Ruby Multi-Store Icon Finder
#
# Description:
#   This script aggressively searches for official application icons across a
#   wide variety of platforms, including app stores and software repositories.
#   It is designed to collect the maximum number of unique icons for each product.
#
# Platforms Searched:
#   - Apple App Store (Mac, iOS, iPad)
#   - Google Play Store
#   - Chrome Web Store
#   - Flathub (for Flatpak apps)
#   - Firefox Browser Add-ons
#   - Microsoft Store (experimental, may be unreliable)
#
# Dependencies:
#   - nokogiri: gem install nokogiri
#
# How to Run:
#   Save this file (e.g., multi_store_finder.rb) and run from your terminal:
#   ruby multi_store_finder.rb
#
# ------------------------------------------------------------------------------

require 'net/http'
require 'uri'
require 'json'
require 'nokogiri'
require 'openssl'
require 'cgi'

# --- Configuration ---
PRODUCTS_TO_SEARCH = [
  "Instapaper", "Pocket", "Raindrop.io", "Safari", "OneNote", "Evernote",
  "Firefox", "Bitwarden", "1Password", "Slack", "Discord", "Spotify", "VLC"
].freeze

# --- Shared Utilities ---

# A robust HTTP fetcher that sets a common user-agent and handles redirects.
def fetch_response(uri, headers = {})
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == 'https')
  http.open_timeout = 15
  http.read_timeout = 15

  default_headers = { 'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.82 Safari/537.36' }
  request = Net::HTTP::Get.new(uri.request_uri, default_headers.merge(headers))
  
  response = http.request(request)

  if response.is_a?(Net::HTTPRedirection) && response['location']
    new_uri = URI.join(uri, response['location'])
    return fetch_response(new_uri, headers)
  end
  response
rescue StandardError => e
  puts "    └─ [Error] Fetch failed for #{uri}: #{e.class} - #{e.message}"
  nil
end

# Helper to build a clean, absolute URL from a base and a path.
def make_absolute_url(base, path)
  return nil if path.nil? || path.strip.empty?
  URI.join(base, path.strip).to_s
rescue URI::InvalidURIError
  nil
end

# --- Platform-Specific Searchers ---

module Searchers
  # Searches all relevant Apple stores.
  def self.apple_app_store(term)
    puts "  ├─ Searching Apple Stores..."
    encoded_term = CGI.escape(term)
    # Search across multiple entities for comprehensive results
    entities = ['software', 'macSoftware', 'iPadSoftware']
    icons = entities.flat_map do |entity|
      api_uri = URI("https://itunes.apple.com/search?term=#{encoded_term}&entity=#{entity}&limit=5")
      response = fetch_response(api_uri)
      next [] unless response&.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      data['results']&.map { |r| r['artworkUrl512'] } || []
    end
    icons.compact.uniq
  end

  # Scrapes the Google Play Store.
  def self.google_play_store(term)
    puts "  ├─ Searching Google Play Store..."
    encoded_term = CGI.escape(term)
    uri = URI("https://play.google.com/store/search?q=#{encoded_term}&c=apps")
    response = fetch_response(uri)
    return [] unless response&.is_a?(Net::HTTPSuccess)
    doc = Nokogiri::HTML(response.body)
    # Selector for app icons in search results
    doc.css('div[role="listitem"] img').map { |img| img['src'] }.compact.uniq
  end

  # Scrapes the Chrome Web Store.
  def self.chrome_web_store(term)
    puts "  ├─ Searching Chrome Web Store..."
    encoded_term = CGI.escape(term)
    uri = URI("https://chromewebstore.google.com/search/#{encoded_term}")
    response = fetch_response(uri)
    return [] unless response&.is_a?(Net::HTTPSuccess)
    doc = Nokogiri::HTML(response.body)
    # Selector for extension icons on the search results page
    doc.css('a > div > img').map { |img| img['src'] }.compact.uniq
  end

  # Scrapes Flathub for Flatpak apps.
  def self.flathub(term)
    puts "  ├─ Searching Flathub..."
    encoded_term = CGI.escape(term)
    uri = URI("https://flathub.org/apps/search?q=#{encoded_term}")
    response = fetch_response(uri)
    return [] unless response&.is_a?(Net::HTTPSuccess)
    doc = Nokogiri::HTML(response.body)
    base_uri = 'https://flathub.org'
    # Selector for app icons on Flathub's search page
    doc.css('a[href^="/apps/details/"] img[src^="/apps/details/"]').map do |img|
      make_absolute_url(base_uri, img['src'])
    end.compact.uniq
  end

  # Scrapes Firefox Browser Add-ons.
  def self.firefox_addons(term)
    puts "  ├─ Searching Firefox Add-ons..."
    encoded_term = CGI.escape(term)
    uri = URI("https://addons.mozilla.org/en-US/firefox/search/?q=#{encoded_term}")
    response = fetch_response(uri)
    return [] unless response&.is_a?(Net::HTTPSuccess)
    doc = Nokogiri::HTML(response.body)
    # Selector for add-on icons
    doc.css('.SearchResult-icon').map { |img| img['src'] }.compact.uniq
  end

  # Scrapes the Microsoft Store (highly experimental).
  def self.microsoft_store(term)
    puts "  ├─ Searching Microsoft Store (Experimental)..."
    encoded_term = CGI.escape(term)
    # The URL structure for search can be complex and change often.
    uri = URI("https://apps.microsoft.com/store/search?q=#{encoded_term}")
    response = fetch_response(uri, {'Accept-Language': 'en-US,en;q=0.5'})
    return [] unless response&.is_a?(Net::HTTPSuccess)
    doc = Nokogiri::HTML(response.body)
    # This selector is very brittle. It looks for images within product cards.
    doc.css('a[href*="/store/detail/"] picture img').map { |img| img['src'] }.compact.uniq
  end

end

# --- Main Orchestration ---
def main
  puts "--- Starting Comprehensive Icon Search ---"
  all_results = {}

  PRODUCTS_TO_SEARCH.each do |product|
    puts "\n🔍 Collecting icons for '#{product}'..."
    collected_icons = []

    # Run all searchers and aggregate the results
    collected_icons.concat(Searchers.apple_app_store(product))
    collected_icons.concat(Searchers.google_play_store(product))
    collected_icons.concat(Searchers.chrome_web_store(product))
    collected_icons.concat(Searchers.flathub(product))
    collected_icons.concat(Searchers.firefox_addons(product))
    collected_icons.concat(Searchers.microsoft_store(product))

    # Remove any duplicates collected from different sources
    unique_icons = collected_icons.compact.uniq
    all_results[product] = unique_icons

    if unique_icons.empty?
      puts "  └─ ❌ No icons found for '#{product}' across all platforms."
    else
      puts "  └─ ✅ Collected #{unique_icons.count} unique icon(s) for '#{product}'."
    end
  end

  puts "\n\n--- Final Report: All Collected Icons ---"
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
