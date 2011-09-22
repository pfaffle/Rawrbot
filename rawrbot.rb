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
Dir["#{$pwd}/plugins/*.rb"].each { |file| require file }

# =============================================================================
# Plugin: RTSearch
#
# Description:
# 	Enables rawrbot to search OIT's Request Tracker ticketing system for basic
# 	ticket data. This plugin simply notices when something appears like a ticket
# 	number, then returns basic info about that ticket such as the Subject,
# 	the Requestors, current Status, and Owner.
#
# Requirements:
# 	none
class RTSearch
	include Cinch::Plugin
	
	match("help", method: :help)
	match(/help rtsearch/i, method: :rt_help)
	
	# Function: help
	#
	# Description: Adds onto the generic help function for other plugins. Prompts
	#   people to use a more specific command to get more details about the
	#   functionality of the module specifically.
	def help(m)
		m.reply "See: !help rtsearch"
	end # End of help function
	
	# Function: rt_help
	#
	# Description: Displays help information for how to use the plugin.
	def rt_help(m)
		m.reply "RT Search"
		m.reply "==========="
		m.reply "Display RT ticket information."
		m.reply "Usage: rt#[ticket number]" 
	end

end
# End of plugin: RTSearch
# =============================================================================




# =============================================================================
# Plugin: Learning
#
# Description:
# 	Enables rawrbot to be taught about various topics/things. If someone tells
# 	rawrbot "x is y", it will store that information in its database. New data
# 	about something is appended to the old entry.
#
# Requirements:
# 	The Ruby gem 'gdbm' must be installed.
class Learning
	include Cinch::Plugin
	
	prefix lambda{ |m| /^#{m.bot.nick}/ }
	
	require 'gdbm'
	
	match(/[:,-]?/)
	match("!help", :use_prefix => false, method: :help)
	match(/^!help learning/i, :use_prefix => false, method: :learning_help)

	# Function: execute
	#
	# Description:
	# 	Determines how to process the command, whether or not the user is trying
	# 	to teach the bot something, make the bot forget something, or retrieve
	# 	information from the bot.
	def execute(m)
		if m.message.match(/[:,-]? ([^(is)]+) is (also )?(.+)/)
			learn(m, $1, $3)
		elsif m.message.match(/[:,-]? (.+) =~ s\/(.+)\/(.+)\//)
			edit(m, $1, $2, $3)
		elsif m.message.match(/[:,-]? forget (.+)/)
			forget(m, $1)
		elsif m.message.match(/[:,-]? literal (.+)/)
			literal(m, $1)
		elsif m.message.match(/[:,-]? (.+)/)
			teach(m, $1)
		elsif m.message.match(/[:,-]?/)
			address(m)
		end
	end # End of execute function

	# Function: learn
	#
	# Description:
	# 	Makes the bot learn something about the given thing. Stores it in the
	# 	learning database.	
	def learn(m, thing, info)
		acknowledgements = ['good to know','got it','roger','understood','OK']
		acknowledgement = acknowledgements[rand(acknowledgements.size)]
		m.reply "#{acknowledgement}, #{m.user.nick}."
		learning_db = GDBM.new("learning.db", mode = 0600)
		thing.downcase!
		if learning_db.has_key? thing
			learning_db[thing] = learning_db[thing] + " or #{info}"
		else
			learning_db[thing] = info
		end
		learning_db.close
	end # End of learn function

	# Function: edit
	#
	# Description:
	# 	Edits an existing entry in the database by using regex syntax.
	def edit(m, thing, find, replace)
		learning_db = GDBM.new("learning.db", mode = 0600)
		thing.downcase!
		if learning_db.has_key? thing
			# edit the entry
			info = learning_db[thing]
			if info.sub!(/#{find}/,replace).nil?
				m.reply "#{thing} doesn't contain '#{find}'."
			else
				learning_db[thing] = info
				m.reply "done, #{m.user.nick}."
			end
		else
			m.reply "I don't know anything about #{thing}."
		end
		learning_db.close
	end # End of edit function.

	# Function: teach
	#
	# Description:
	# 	Makes the bot teach the user what it knows about the given thing, as
	# 	it is stored in the database.
	def teach(m, thing)
		learning_db = GDBM.new("learning.db", mode = 0600)
		thing.downcase!
		if learning_db.has_key? thing
			info = learning_db[thing]

			# If the entry contains pipe characters, split it into substrings delimited
			# by those pipe characters, then choose one randomly to spit back out.
			if info.match(/\|/)
				split_entries = info.split '|'
				info = split_entries[rand(split_entries.size)]
			end
			
			# If the entry contains the prefix <reply>, reply by simply saying
			# anything following it, rather than saying 'x is y'.
			if info.match(/^<reply> ?(.+)/)
				m.reply $1
			else
				m.reply "#{thing} is #{info}."
			end
		else
			giveups = ["bugger all, I dunno, #{m.user.nick}.","no idea, #{m.user.nick}.","dunno, #{m.user.nick}."]
			giveups.concat ['huh?','what?']
			giveup = giveups[rand(giveups.size)]
			m.reply "#{giveup}"
		end
		learning_db.close
	end # End of teach function

	# Function: forget
	#
	# Description:
	# 	Makes the bot forget whatever it knows about hte given thing. Removes
	# 	that key from the database.
	def forget(m, thing)
		learning_db = GDBM.new("learning.db", mode = 0600)
		thing.downcase!
		if learning_db.has_key? thing
			learning_db.delete thing
			m.reply "I forgot #{thing}."
		else
			m.reply "I don't know anything about #{thing}."
		end
		learning_db.close
	end # End of forget function

	# Function: literal
	#
	# Description:
	# 	Displays the literal contents of the database entry for the given thing,
	# 	without parsing special syntax like <reply> and |.
	def literal(m, thing)
		learning_db = GDBM.new("learning.db", mode = 0600)
		thing.downcase!
		if learning_db.has_key? thing
			info = learning_db[thing]
			m.reply "#{thing} =is= #{info}."
		else
			m.reply "No entry for #{thing}"
		end
		learning_db.close
	end

	# Function: address
	#
	# Description:
	# 	If the bot is named but given no arguments, it responds with this function.
	def address(m)
		replies = ["#{m.user.nick}?",'yes?','you called?','what?']
		my_reply = replies[rand(replies.size)]
		m.reply my_reply
	end # End of address function

	# Function: help
	#
	# Description: Adds onto the generic help function for other plugins. Prompts
	#   people to use a more specific command to get more details about the
	#   functionality of the module specifically.
	def help(m)
		m.reply "See: !help learning"
	end # End of help function
	
	# Function: learning_help
	#
	# Description: Displays help information for how to use the plugin.
	def learning_help(m)
		m.reply "Learning module"
		m.reply "==========="
		m.reply "Description: Teach the bot about things, and have it repeat that info back later."
		m.reply "Usage: [botname] [thing] is [information] (to store additional [information]	under the keyword [thing].)"
		m.reply "[botname] [thing] (to get whatever the bot knows about [thing].)"
	end
	

end
# End of plugin: Learning
# =============================================================================

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
