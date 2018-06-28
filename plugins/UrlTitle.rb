require 'uri'
require 'lib/http_title'

# Fetches URLs that it sees, grabs the title of the page, then displays it in
# the IRC channel, so people know what to expect before clicking on links.
class UrlTitle
  include Cinch::Plugin

  set(:prefix, ->(m) { m.bot.config.plugins.prefix })

  match(/http|https/i, method: :tell_page_title, use_prefix: false)

  def initialize(m)
    super
    @http_title = HttpTitle.new
  end

  # For testing
  def use_http_title(http_title)
    @http_title = http_title
  end

  def tell_page_title(m)
    get_uris(m.message).each do |uri|
      title = @http_title.get(uri)
      m.reply(title) if title
    end
  end

  private

  def get_uris(msg)
    msg.scan(/(#{URI.regexp(%w[http https])})/i).collect do |match|
      URI.parse(match.first)
    end
  end
end
