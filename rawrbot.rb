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
# Plugin: Karma
#
# Description:
# 	Tracks positive and negative karma for a given item. Increments
# 	karma when someone adds a ++ after a word (or a series of words 
# 	encapsulated by parentheses) and decrements karma when someone
# 	adds -- to the same.
#
# Requirements:
# 	The Ruby gem 'gdbm' must be installed.
class Karma
	include Cinch::Plugin
	
	require 'gdbm'

	match(/\S+\+\+/, method: :increment, :use_prefix => false)
	match(/\S+--/, method: :decrement, :use_prefix => false)
	match(/karma (.+)/, method: :display)
	match(/help karma/i, method: :karma_help)
	match("help", method: :help)

	# Function: increment
	#
	# Description: Increments karma by one point for each object
	# that has a ++ after it.
	#
	# Converts karma value to a Fixnum (int), adds 1, then converts back to
	# a String, because GDBM doesn't seem to like to store
	# anything but Strings. If an element reaches neutral (0) karma,
	# it deletes it from the DB so the DB doesn't grow any larger
	# than it has to.
	def increment(m)
		karma_db = GDBM.new("karma.db", mode = 0600)
		matches = m.message.scan(/\([^)]+\)\+\+|\S+\+\+/)
	
		matches.each do |element|
			element.downcase!
			if element =~ /\((.+)\)\+\+/
				if karma_db.has_key? $1
					if karma_db[$1] == "-1"
						karma_db.delete $1	
					else
						karma_db[$1] = (karma_db[$1].to_i + 1).to_s
					end
				else
					karma_db[$1] = "1"
				end
			elsif element =~ /(\S+)\+\+/
				if karma_db.has_key? $1
					if karma_db[$1] == "-1"
						karma_db.delete $1
					else
						karma_db[$1] = (karma_db[$1].to_i + 1).to_s
					end
				else
					karma_db[$1] = "1"
				end
			end
		end

		karma_db.close
	end # End of increment function
	
	# Function: decrement
	#
	# Description: Decrements karma by one point for each object
	# that has a -- after it.
	#
  # Converts karma value to a Fixnum (int), subtracts 1, then converts back to
	# a String, because GDBM doesn't seem to like to store
	# anything but Strings. If an element reaches neutral (0) karma,
	# it deletes it from the DB so the DB doesn't grow any larger
	# than it has to.
	def decrement(m)
		karma_db = GDBM.new("karma.db", mode = 0600)
		matches = m.message.scan(/\([^)]+\)--|\S+--/)
		
		matches.each do |element|
			element.downcase!
			if element =~ /\((.+)\)--/
				if karma_db.has_key? $1
					if karma_db[$1] == "1"
						karma_db.delete $1	
					else
						karma_db[$1] = (karma_db[$1].to_i - 1).to_s
					end
				else
					karma_db[$1] = "-1"
				end
			elsif element =~ /(\S+)--/
				if karma_db.has_key? $1
					if karma_db[$1] == "1"
						karma_db.delete $1	
					else
						karma_db[$1] = (karma_db[$1].to_i - 1).to_s
					end
				else
					karma_db[$1] = "-1"
				end
			end
		end

		karma_db.close
	end # End of decrement function
	
	# Function: display
	#
	# Description: Displays the current karma level of the requested element.
	#   If the element does not exist in the DB, it has neutral (0) karma.
	def display(m,arg)
		karma_db = GDBM.new("karma.db", mode = 0600)
		arg.downcase!
		if karma_db.has_key?("#{arg}")
			m.reply "#{arg} has karma of #{karma_db[arg]}."
		else
			m.reply "#{arg} has neutral karma."
		end
		karma_db.close
	end # End of display function

	# Function: karma_help
	#
	# Description: Displays help information for how to use the Karma plugin.
	def karma_help(m)
		m.reply "Karma tracker"
		m.reply "==========="
		m.reply "Description: Tracks karma for things. Higher karma = liked more, lower karma = disliked more."
		m.reply "Usage: !karma foo (to see karma level of 'foo')"
		m.reply "foo++ (foo bar)++ increments karma for 'foo' and 'foo bar'"
		m.reply "foo-- (foo bar)-- decrements karma for 'foo' and 'foo bar'"
	end
	
	# Function: help
	#
	# Description: Adds onto the generic help function for other plugins. Prompts
	#   people to use a more specific command to get more details about the
	#   functionality of the Karma module specifically.
	def help(m)
		m.reply "See: !help karma"
	end

end
# End of plugin: Karma
# =============================================================================

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
