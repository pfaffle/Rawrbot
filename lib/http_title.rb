require 'uri'
require 'open-uri'
require 'nokogiri'

# Takes a uri, fetches the title of the webpage at that address and returns it.
class HttpTitle
  def get(uri)
    if uri.is_a?(URI::HTTP)
      get_page_title(uri)
    else
      get_page_title(to_uri(uri.to_s))
    end
  end

  private

  def to_uri(text)
    uri = URI.parse(text)
    raise ArgumentError, 'Not an HTTP/HTTPS URI' if uri.nil? || !uri.is_a?(URI::HTTP)
    uri
  end

  def get_page_title(uri)
    title = Nokogiri::HTML(uri.open(:read_timeout => 5)).css('title').first.text
    strip_white_space(title)
  end

  def strip_white_space(str)
    str.strip.gsub(/\s+/, ' ')
  end
end
