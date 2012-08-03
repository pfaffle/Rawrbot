# =============================================================================
# Plugin: Twitter Feed
#
# Description:
# 	Enables Rawrbot to parse Twitter feeds and spit out tweets into specific
# 	channels in IRC.
#
# Requirements:
# 	- A file 'twitter_config.rb' with information on what feeds to check and what
# 		channels to print tweets to.
# 	- The Ruby gem 'json_pure'
#
class Twitter
	include Cinch::Plugin
	
	@@active = false
	@@feeds = Array.new
	@@threads = Array.new

	require 'net/http'
	require 'json/pure'

	match /twitter on$/i, method: :start_ticker
	match /twitter off$/i, method: :stop_ticker
	match /twitter restart$/i, method: :restart_ticker
	match /twitter$/i, method: :report_status
	match /help$/i, method: :help
	match /help twitter$/i, method: :twitter_help

	listen_to :connect, method: :quiet_start_ticker

	# Function: start_ticker
	#
	# Description:
	#   Starts looking at the Twitter feeds we've subscribed to in the config
	#   file and kicks off independent Threads for each one, checking them
	#   periodically to see if there is a new tweet.
	def start_ticker(m)
		quiet_start_ticker(m)
		m.reply "Twitter Feed: On"
	end

	# Function: quiet_start_ticker
	#
	# Description:
	#   Does what start_ticker does except without output.
	def quiet_start_ticker(m)
		if (!@@active)
			@@active = true
			load "#{$pwd}/plugins/config/twitter_config.rb"
			twitter_config = return_twitter_config
			twitter_config['usernames'].each do |feed|
				http = Net::HTTP.new('api.twitter.com',80)
				query = "/1/users/show.json?screen_name=#{feed}&include_entities=true"
				resp, rawdata = http.get(query)
				data = JSON.parse(rawdata)
				if (resp.is_a? Net::HTTPOK)
					@@feeds.push(feed)
					@@threads.push( Thread.new {run_ticker(m,data,twitter_config['frequency'],twitter_config['channels'])} )
					# Eventually I'll figure out how to do this using Cinch's built-in
					# logging/status messages.
					puts "[Twitter] Subscribed to feed '#{feed}'."
				elsif (resp.is_a? Net::HTTPNotFound)
					puts "[Twitter] Unable to subscribe to feed '#{feed}': Not found."
				elsif (resp.is_a? Net::HTTPForbidden)
					puts "[Twitter] Unable to subscribe to feed '#{feed}': User suspended."
				else
					puts "[Twitter] Unable to subscribe to feed '#{feed}': Unknown error."
				end
			end
		end
	end

	# Function: stop_ticker
	#
	# Description:
	#   Kills off the Threads looking at Twitter so we stop processing them.
	def stop_ticker(m)
		quiet_stop_ticker(m)
		m.reply "Twitter Feed: Off"
	end
	
	# Function: quiet_stop_ticker
	#
	# Description:
	#   Does what stop_ticker does except without output.
	def quiet_stop_ticker(m)
		if (@@active)
			@@active = false
			@@threads.each do |thread|
				thread.kill
			end
			@@threads.clear
			@@feeds.clear
		end
	end

	# Function: restart_ticker
	#
	# Description:
	#   Kills Twitter Threads and then restarts them. Good for re-loading an updated
	#   config file without restarting the bot.
	def restart_ticker(m)
		quiet_stop_ticker(m)
		quiet_start_ticker(m)
		m.reply "Twitter Feed: Restarted"
	end

	# Function: report_status
	#
	# Description:
	#   Reports the current status of the Twitter mod (i.e. on/off). If on, also reports
	#   what Twitter feeds are currently being monitored.
	def report_status(m)
		if (@@active)
			m.reply "Twitter Feed: On"
			reply = "Feeds subscribed to:"
			if (@@feeds.empty?)
				reply = "None"
			else
				@@feeds.each do |feed|
					reply << " #{feed},"
				end
				reply = reply[0,reply.size - 1]
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
	def run_ticker(m,data,freq,channel_list)
		source = 'api.twitter.com'
		http = Net::HTTP.new(source,80)
		feed = data['screen_name']
		query = "/1/users/show.json?screen_name=#{feed}&include_entities=true"
		
		# Get current Tweet. Don't report it - wait until a new one appears.
		cur_msg = data['status']['text']
#		puts "[Twitter] User #{feed}'s current tweet: #{cur_msg}."

		# Generate a random time offset between 0-60 seconds to actually report results, so 
		# that updates don't all get spit out at the same time.
		offset = rand(60)
		wait_time = freq + offset

		# Begin checking and waiting for updates.
		while (@@active)
			sleep(wait_time)
					
			resp, rawdata = http.get(query)
			data = JSON.parse(rawdata)
			
#			puts "[Twitter] User #{feed}'s updated tweet: #{data['status']['text']}."
			# If most recent tweet has changed, update, then report it.
			if (cur_msg != data['status']['text'])
#				puts "[Twitter] ... Different from current tweet of: #{cur_msg}."
				cur_msg = data['status']['text']
				reply = "[@#{feed}] #{cur_msg}"
				
				# Report results to each channel in the list.
				channel_list.each do |chname|
					max_msg_size = 512 - m.bot.nick.size - chname.size - 43
					Channel(chname).send reply[0,max_msg_size]
				end
			else
#				puts "[Twitter] ... Same as current tweet of: #{cur_msg}."
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
		m.reply "  !twitter restart (to restart reporting, or reload a new config)"
		m.reply "Ask a bot admin to add/remove Twitter feeds."
	end

	def help(m)
		m.reply "See: !help twitter"
	end

end
# End of plugin: Twitter Feed
# =============================================================================
