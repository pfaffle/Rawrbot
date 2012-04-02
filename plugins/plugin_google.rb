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
	
	@@active = false
	@@current_msg = String.new

	require 'sanitize'
	require 'rss/1.0'
	require 'rss/2.0'

	match /rss on$/i, method: :start_ticker
	match /rss off$/i, method: :stop_ticker
	match /rss$/i, method: :report_status

	def start_ticker(m)
		m.reply "Google RSS: On"
		if (!@@active)
			@@active = true

			while (@@active)
				source = "http://www.google.com/appsstatus/rss/en"
				raw = String.new
				open(source) do |input|
					raw = input.read
				end
				rss = RSS::Parser.parse(raw, false)

				if (rss.items.size > 0)
					if (rss.items[0].description.hash != @@current_msg.hash)
						@@current_msg = rss.items[0].description
						max_msg_size = 512 - m.bot.nick.size - m.channel.name.size - 43
	
						cleaned_rss = Sanitize.clean(rss.items[0].description)
						msg_set = cleaned_rss.split "\u00A0"
		
						reply = "[#{rss.items[0].title}] "
						reply << "#{msg_set[0]}"
						if (reply.size < max_msg_size)
							reply << "#{msg_set[1]}"
						end
						m.reply reply[0,max_msg_size]
						m.reply "More info at: #{rss.items[0].link}"
					end
				end

				# This is kind of janky but I'm not sure how else to do it.
				for i in 0..15
					sleep(1)
					if (!@@active)
						return
					end
				end

			end
		end
	end

	def stop_ticker(m)
		@@active = false
		@@current_msg = ""
		m.reply "Google RSS: Off"
	end

	def report_status(m)
		if (@@active)
			m.reply "Google RSS: On"
		else
			m.reply "Google RSS: Off"
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
