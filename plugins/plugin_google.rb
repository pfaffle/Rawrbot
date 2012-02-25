# =============================================================================
# Plugin: Google RSS Feed
#
# Description:
#		Collects information from the Google Apps Status Dashboard
#		RSS feed, then reports it to an IRC channel to alert users
#		of outages.
#
# Requirements:
# 	The Ruby gem 'sanitize' must be installed. (version 2.0.3)
#
class GoogleRSS
	include Cinch::Plugin
	
	require 'sanitize'
	require 'rss/1.0'
	require 'rss/2.0'

	match /rss on$/i, method: :start_ticker
	match /rss off$/i, method: :stop_ticker
	match /rss$/, method: :report_status

	def start_ticker(m)
		source = "http://www.google.com/appsstatus/rss/en"
		raw = String.new
		open(source) do |input|
			raw = input.read
		end
		rss = RSS::Parser.parse(raw, false)

		max_msg_size = 512 - m.bot.nick.size - m.channel.name.size - 43
		
		cleaned_rss = Sanitize.clean(rss.items[0].description)
		msg_set = cleaned_rss.split "\u00A0"

		reply = "[#{rss.items[0].title}] "
		reply << "#{msg_set[1][0,max_msg_size]}"
		m.reply reply
		m.reply "More info at: #{rss.items[0].link}"
	end

	def execute(m)
		m.reply "This is a test."
	end

	def google_help(m)
		m.reply "Google Apps Status RSS feed"
		m.reply "==========="
		m.reply "Description: Periodically checks the Google Apps Status RSS feed and report any outages and when they are resolved."
		m.reply "Usage: !rss on (to start reporting)"
		m.reply "!rss off (to disable reporting)"
	end

	def help(m)
		m.reply "See: !help google"
	end
end
