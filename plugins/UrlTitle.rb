# Fetches URLs that it sees, grabs the title of the page, then displays it in
# the IRC channel, so people know what to expect before clicking on links.
class UrlTitle
  include Cinch::Plugin

  require 'uri'
  require 'open-uri'
  require 'nokogiri'

  set :prefix, lambda { |m| m.bot.config.plugins.prefix }

  match /http|https/i, method: :tellPageTitle, :use_prefix => false

  def tellPageTitle(m)
    title = getPageTitle(getUrl(m.message))
    m.reply(title) if title
  end

  def getUrl(msg)
    msg =~ /(#{URI::regexp(['http','https'])})/i
    url = URI::parse($1)
    return url.is_a?(URI::HTTP) ? url : nil
  end

  def getPageTitle(url)
    if (url)
      title = Nokogiri::HTML(url.open(:read_timeout => 5)).css('title')[0].text
      return stripWhiteSpace(title)
    end
  end

  def stripWhiteSpace(str)
      return str.gsub(/\s+/,' ').strip
  end
end
