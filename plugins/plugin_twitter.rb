# =============================================================================
# Plugin: Twitter Feed
#
# Description:
# 	Enables Rawrbot to parse Twitter feeds and spit out tweets into specific
# 	channels in IRC.
#
# Requirements:
# 	- A file 'config_twitter.rb' with information on what feeds to check and what
# 		channels to print tweets to.
# 	- The Ruby gem 'json_pure'
#
class Twitter
	include Cinch::Plugin
	
	@@active = true
	@@feeds = Array.new
	@@threads = Array.new

	require 'net/http'
	require 'json/pure'

	match /twitter on$/i, method: :start_ticker
	match /twitter off$/i, method: :stop_ticker
	match /twitter restart$/i, method: :restart_ticker
	match /twitter$/i, method: :report_status

	listen_to :connect, method: :quiet_start_ticker

	# Function: start_ticker
	#
	# Description:
	#   Starts looking at the Twitter feeds we've subscribed to in the config
	#   file and kicks off independent Threads for each one, checking them
	#   periodically to see if there is a new tweet.
	def start_ticker(m)
		m.reply "Twitter Feed: On"
		if (!@@active)
			quiet_start_ticker(m)
		end
	end

	# Function: quiet_start_ticker
	#
	# Description:
	#   Does what start_ticker does except without output.
	def quiet_start_ticker(m)
		@@active = true
		load "#{$pwd}/plugins/config_twitter.rb"
		twitter_config = twitter_return_config
		twitter_config['usernames'].each do |feed|
			@@feeds.push(feed)
			@@threads.push( Thread.new {run_ticker(m,feed,twitter_config['frequency'],twitter_config['channels'])} )
		end
	end

	# Function: stop_ticker
	#
	# Description:
	#   Kills off the Threads looking at Twitter so we stop processing them.
	def stop_ticker(m)
		m.reply "Twitter Feed: Off"
		@@active = false
		@@threads.each do |thread|
			thread.kill()
			@@threads.pop()
			@@feeds.pop()
		end
	end
	
	# Function: restart_ticker
	#
	# Description:
	#   Kills Twitter Threads and then restarts them. Good for re-loading an updated
	#   config file without restarting the bot.
	def restart_ticker(m)
		stop_ticker(m)
		start_ticker(m)
	end

	# Function: report_status
	#
	# Description:
	#   Reports the current status of the Twitter mod (i.e. on/off). If on, also reports
	#   what Twitter feeds are currently being monitored.
	def report_status(m)
		if (@@active)
			m.reply "Twitter Feed: On"
			reply = "Feeds subscribed to: "
			@@feeds.each do |feed|
				reply << "#{feed} "
			end
			m.reply reply
		else
			m.reply "Twitter Feed: Off"
		end
	end
	
	# Function: run_ticker
	#
	# Description:
	#   Periodically checks a particular Twitter account for new activity. When the latest
	#   tweet (that it knows about) changes, it reports the new tweet to all the subscribed
	#   IRC channels.
	def run_ticker(m,feed,freq,channel_list)
		source = 'api.twitter.com'
		http = Net::HTTP.new(source,80)
		query = "/1/users/show.json?screen_name=#{feed}&include_entities=true"
		resp, rawdata = http.get(query)
		
		# Get current Tweet. Don't report it - wait until a new one appears.
		cur_msg = data['status']['text']
	
		# Generate a random time offset between 0-60 seconds to actually report results, so 
		# that updates don't all get spit out at the same time.
		offset = rand(60)
		wait_time = freq + offset

		# Begin checking and waiting for updates.
		while (@@active)
			sleep(wait_time)
					
			resp, rawdata = http.get(query)
			data = JSON.parse(rawdata)
			
			# If most recent tweet has changed, update the old one, then report it.
			if (cur_msg.hash != data['status']['text'].hash)
				cur_msg = data['status']['text']
				reply = "[@#{feed}] #{cur_msg}"
				
				# Report results to each channel in the list.
				channel_list.each do |chname|
					max_msg_size = 512 - m.bot.nick.size - chname.size - 43
					Channel(chname).send reply[0,max_msg_size]
				end
			end

		end
	end

	def twitter_help(m)
		m.reply "Twitter feed"
		m.reply "==========="
		m.reply "Description: Periodically checks Twitter feeds and prints new tweets."
		m.reply "Usage:"
	  m.reply "  !twitter on (to start reporting)"
		m.reply "  !twitter off (to stop reporting)"
		m.reply "  !twitter restart (to restart reporting, reloading a new config)"
	end

	def help(m)
		m.reply "See: !help twitter"
	end

end
# End of plugin: Twitter Feed
# =============================================================================
