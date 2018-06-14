require 'cgi'
require 'nokogiri'
require 'uri'

class UrbanDictionary
  include Cinch::Plugin

  set :prefix, lambda { |m| m.bot.config.plugins.prefix }

  match /urban (.+)/

  def lookup(word)
    url = "http://www.urbandictionary.com/define.php?term=#{CGI.escape(word)}"
    CGI.unescape_html Nokogiri::HTML(URI(url).open).at("div.meaning").text.gsub(/\s+/, ' ') rescue nil
  end

  def execute(m, word)
    m.reply(lookup(word) || "No results found", true)
  end
end
