#!/usr/bin/env ruby
# (c) Craig Meinschein 2011
# Licensed under the GPLv3 or any later version.
# File:			rawrbot.rb
# Description:
# 	rawrbot. An irc bot implemented in Ruby, using the Cinch framework from:
#	 	http://www.rubyinside.com/cinch-a-ruby-irc-bot-building-framework-3223.html
#		A work in progress.


$pwd = Dir.pwd
require 'cinch'
Dir["#{$pwd}/plugins/*plugin*.rb"].each do |file| 
	require file
	puts "Loading #{file}."
end

# =============================================================================
# Plugin: Social
#
# Description:
# 	A friendly plugin, which makes the bot communicate with people who talk
# 	to it.
#
# Requirements:
# 	none
class Social
	include Cinch::Plugin

	match(/hello|hi|howdy|hey|greetings/i, :use_prefix => false, method: :greet)
	match(/(good)? ?(morning|afternoon|evening|night)/i, :use_prefix => false, method: :timeofday_greet)
	match(/(good)?bye|adios|farewell|later|see ?(ya|you|u)|cya/i, :use_prefix => false, method: :farewell)

	# Function: greet
	#
	# Description:
	# 	Say hi!
	def greet(m)
		if m.message.match(/(hellos?|hi(ya)?|howdy|hey|greetings|yo|sup|hai|hola),? #{m.bot.nick}/i)
			greetings = ['Hello','Hi','Hola','Ni hao','Hey','Yo','Howdy']
			greeting = greetings[rand(greetings.size)]
			m.reply "#{greeting}, #{m.user.nick}!"
		end
	end # End of greet function
	
	# Function: timeofday_greet
	#
	# Description:
	# 	Gives a time of day-specific response to a greeting. i.e. 'good morning'.
	def timeofday_greet(m)
		if m.message.match(/(good)? ?(morning|afternoon|evening|night),? #{m.bot.nick}/i)
			m.reply "Good #{$2.downcase}, #{m.user.nick}!"
		end
	end # End of timeofday_greet function

	# Function: farewell
	#
	# Description:
	# 	Says farewell.
	def farewell(m)
		farewells = ['Bye','Adios','Farewell','Later','See ya','See you','Take care']
		farewell = farewells[rand(farewells.size)]
		if m.message.match(/((good)?bye|adios|farewell|later|see ?(ya|you|u)|cya),? #{m.bot.nick}/i)
			m.reply "#{farewell}, #{m.user.nick}!"
		end
	end
end
# End of plugin: Social
# =============================================================================

# =============================================================================
# Plugin: Messenger
#
# Description:
# 	Sends a PM to a user.
#
# Requirements:
# 	none
class Messenger
	include Cinch::Plugin
	
	match(/tell (.+?) (.+)/)
	
	# Function: execute
	#
	# Description:
	# 	Tells someone something.
	def execute(m, receiver, message)
		m.reply "Done."
		User(receiver).send(message)
	end
end
# End of plugin: Messenger
# =============================================================================


# Launch the bot.
bot = Cinch::Bot.new do
	require "#{$pwd}/config.rb"
	config_hash = ret_config
	configure do |config|
		config.server		= config_hash['server']
		config.port			= config_hash['port']
		config.channels	= config_hash['channels']
		config.ssl.use	= config_hash['ssl']
		config.nick			= config_hash['nick']
		config.realname	= config_hash['realname']
		config.user			= config_hash['user']
		config.plugins.plugins = [LDAPsearch,Social,Messenger,Karma,Learning,RTSearch]
	end
end

# [2011/08/06 12:10:15.783] >> :pfafflebot MODE pfafflebot:+iwz

bot.start
