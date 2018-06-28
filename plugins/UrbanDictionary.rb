require 'cgi'
require 'nokogiri'
require 'uri'

# Plugin which searches Urban Dictionary and prints the results for that query
class UrbanDictionary
  include Cinch::Plugin

  set(:prefix, ->(m) { m.bot.config.plugins.prefix })

  match(/urban (.+)/)

  def lookup(word)
    url = "http://www.urbandictionary.com/define.php?term=#{CGI.escape(word)}"
    CGI.unescape_html Nokogiri::HTML(URI(url).open).at('div.meaning').text.gsub(/\s+/, ' ')
  end

  def execute(m, word)
    m.reply(lookup(word) || 'No results found', true)
  end
end
