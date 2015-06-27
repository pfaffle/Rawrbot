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
    return msg =~ /(#{URI::regexp(['http','https'])})/i ? $1 : nil
  end

  def getPageTitle(url)
    if (url)
      title = Nokogiri::HTML(open(url)).css('title').text
      return title ? title.strip.delete("\t\r\n").squeeze(" ") : nil
    end
  end
end
