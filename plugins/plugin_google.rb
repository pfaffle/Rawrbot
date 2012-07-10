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
	
	@@active = true
	@@current_msg = String.new

	require 'sanitize'
	require 'rss/1.0'
	require 'rss/2.0'

	match /rss on$/i, method: :start_ticker
	match /rss off$/i, method: :stop_ticker
	match /rss$/i, method: :report_status

	listen_to :connect, method: :run_ticker

	def start_ticker(m)
		m.reply "Google RSS: On"
		if (!@@active)
			@@active = true
			run_ticker(m)
		end
	end

	def stop_ticker(m)
		m.reply "Google RSS: Off"
		@@active = false
		@@current_msg = ""
	end

	def report_status(m)
		if (@@active)
			m.reply "Google RSS: On"
		else
			m.reply "Google RSS: Off"
		end
	end

	def run_ticker(m)
		load "#{$pwd}/plugins/config_google.rb"
		source = "http://www.google.com/appsstatus/rss/en"
		channel_list = google_return_config
		
		while (@@active)
			raw = String.new
			open(source) do |input|
				raw = input.read
			end
			rss = RSS::Parser.parse(raw, false)

			if (rss.items.size > 0)
				if (rss.items[0].description.hash != @@current_msg.hash)
					@@current_msg = rss.items[0].description

					cleaned_rss = Sanitize.clean(rss.items[0].description)
					msg_set = cleaned_rss.split "\u00A0"
	
					reply = "[#{rss.items[0].title}] "
					reply << "#{msg_set[0]}"
					
					# Report RSS results to each channel in the list.
					channel_list.each do |chname|
						max_msg_size = 512 - m.bot.nick.size - chname.size - 43
						Channel(chname).send reply[0,max_msg_size]
						Channel(chname).send "More info at: #{rss.items[0].link}"
					end
				end
			end

			# This is kind of janky but I'm not sure how else to do it.
			for i in 0..15
				sleep(1)
				if (!@@active)
					return
				end
				if (m.bot.quitting)
					return
				end
			end

		end
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
# End of plugin: Google RSS Feed
# =============================================================================
