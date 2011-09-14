#!/usr/bin/env ruby
# (c) Craig Meinschein 2011
# Licensed under the GPLv3 or any later version.
# File:			rawrbot.rb
# Description:
# 	rawrbot. An irc bot implemented in Ruby, using the Cinch framework from:
#	 	http://www.rubyinside.com/cinch-a-ruby-irc-bot-building-framework-3223.html
#		A work in progress.


require 'cinch'
$pwd = Dir.pwd

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

# =============================================================================
# Plugin: LDAPsearch
#
# Description:
# 	Searches LDAP for an account, and returns
# 	results about that account if found.
#
# Requirements:
#		- The Ruby gem NET-LDAP
#		- Authentication information for NET-LDAP in the file 'ldap_auth.rb'.
#		- Rawrbot must be running on PSU's IP space (131.252.x.x).
class LDAPsearch
	include Cinch::Plugin
	
	require 'net/ldap'
	match(/help ldap/i, method: :ldap_help)
	match("help", method: :help)
	match(/ldap (.+)/)
	
	# Function: execute
	#
	# Description: Parses the search query and executes a search on LDAP to retrieve
	# account information. Automatically decides what field of LDAP to search based
	# on what the query looks like. It then prints the results to the IRC user who
	# made the request.
	def execute(m, query)
		
		# Error-checking to sanitize input. i.e. no illegal symbols.
		if query =~ /[^\w@._-]/
			m.reply "Invalid search query '#{query}'"
			return
		end	
		
		# Determine what field to search and proceed to execute it.
		if query =~ /@pdx.edu/
			type = 'email alias'
			attribute = 'mail'
		elsif query =~ /@/
			type = 'forwarding address'
			attribute = 'mailRoutingAddress'
		else
			type = 'username'
			attribute = 'uid'
		end
		m.reply "Performing LDAP search on #{type} #{query}."
		
		ldap_entry = ldap_search attribute,query
	
		#	Piece together the final results and print them out in user-friendly output.
		reply = String.new
		if ldap_entry['dn'].empty?
			reply = "Error: No results.\n"
		elsif ldap_entry['dn'].length > 1
			# Realistically this case should never happen because we filtered '*'
			# out of the search string earlier. If this comes up, something in LDAP
			# is really janky. The logic to account for this is here nonetheless,
			# just in case.
			reply = "Error: Too many results.\n"
		else
			#	Get name, username and dept of the user.
			ldap_entry['gecos'].each { |name| reply << "Name: #{name}\n" }
			ldap_entry['uid'].each { |uid| reply << "Username: #{uid}\n" }
			ldap_entry['ou'].each { |dept| reply << "Dept: #{dept}\n" }
			
			# Determine if the user has opted-in to Google Mail.
			ldap_entry['mailhost'].each do |mhost|
				if mhost =~ /gmx.pdx.edu/
					reply << "Google: yes\n"
				else
					reply << "Google: no\n"
				end
			end
			
			# Determine if this is a sponsored account, and if so, who the sponsor is.
			if ldap_entry['psusponsorpidm'].empty?
				reply << "Sponsored: no\n"
			else
				# Look up sponsor's information.
				reply << "Sponsored: yes\n"
				sponsor_uniqueid = ldap_entry['psusponsorpidm'][0]
				
				ldap_sponsor_entry = ldap_search "uniqueIdentifier",sponsor_uniqueid
				
				sponsor_name = ldap_sponsor_entry['gecos'][0]
				sponsor_uid = ldap_sponsor_entry['uid'][0]
				reply << "Sponsor: #{sponsor_name} (#{sponsor_uid})\n"
			end
			
			# Determine the account and password expiration dates. Also, estimate the date the
			# password was originally set by subtracting 6 months from the expiration date.
			ldap_entry['psuaccountexpiredate'].each do |acctexpiration|
				d = parse_date acctexpiration
				reply << "Account expires: #{d['month']} #{d['day']}, #{d['year']} at #{d['hour']}:#{d['min']}:#{d['sec']}\n"
			end
			ldap_entry['psupasswordexpiredate'].each do |pwdexpiration|
				d = parse_date pwdexpiration
				reply << "Password expires: #{d['month']} #{d['day']}, #{d['year']} at #{d['hour']}:#{d['min']}:#{d['sec']}\n"
				e = d.dup
				if e['month'] =~ /January/
				 	e['month'] = 'July'
				elsif e['month'] =~ /February/ 
					e['month'] = 'August'
				elsif e['month'] =~ /March/
					e['month'] = 'September'
				elsif e['month'] =~ /April/
					e['month'] = 'October'
				elsif e['month'] =~ /May/
					e['month'] = 'November'
				elsif e['month'] =~ /June/
					e['month'] = 'December'
				elsif e['month'] =~ /July/
					e['month'] = 'January'
				elsif e['month'] =~ /August/
					e['month'] = 'February'
				elsif e['month'] =~ /September/
					e['month'] = 'March'
				elsif e['month'] =~ /October/
					e['month'] = 'April'
				elsif e['month'] =~ /November/
					e['month'] = 'May'
				elsif e['month'] =~ /December/
					e['month'] = 'June'
				end
				if e['year'] == '2012' # Being lazy. I will have to fix this logic eventually.
					e['year'] == '2011'
				end
				reply << "Password was set: #{e['month']} #{e['day']}, #{e['year']} at #{e['hour']}:#{e['min']}:#{e['sec']}\n"
			end
			
			# Determine if email is being forwarded to an external address.
			ldap_entry['mailroutingaddress'].each do |forward|
				# If they are on Google, we cannot tell if they are forwarding.
				if ldap_entry['mailhost'][0] =~ /gmx.pdx.edu/
					reply << "Email forwarded to: Unable to determine with Gmail.\n"
				else
					reply << "Email forwarded to: #{forward}\n"
				end
			end

			# Print out any email aliases.
			ldap_entry['maillocaladdress'].each { |email_alias| reply << "Email alias: #{email_alias}\n" }

		end

		# Send results via PM so as to not spam the channel.
		User(m.user.nick).send(reply)

	end # End of execute function.
	
	# Function: parse_date
	#
	# Description: Parses a String containing a date in Zulu time, and returns
	# it as a Hash with each component under a separate key.
	#
	# Arguments:
	# - A String, containing a date/time in Zulu time:
	#   yyyymmddhhmmssZ
	#
	# Returns:
	# - A Hash, containing the parsed date in human-readable format.
	# 	'year' => '2011'
	# 	'month' => 'January'
	# 	'day' => '03'
	# 	also 'hour','min',sec'
	def parse_date date
		unless date =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z/
			return nil
		end
		
		return_date = {
			'year' => $1,
			'month' => $2,
			'day' => $3,
			'hour' => $4,
			'min' => $5,
			'sec' => $6
		}

		return_date['month'] = 'January' if return_date['month'] == '01'
		return_date['month'] = 'February' if return_date['month'] == '02'
		return_date['month'] = 'March' if return_date['month'] == '03'
		return_date['month'] = 'April' if return_date['month'] == '04'
		return_date['month'] = 'May' if return_date['month'] == '05'
		return_date['month'] = 'June' if return_date['month'] == '06'
		return_date['month'] = 'July' if return_date['month'] == '07'
		return_date['month'] = 'August' if return_date['month'] == '08'
		return_date['month'] = 'September' if return_date['month'] == '09'
		return_date['month'] = 'October' if return_date['month'] == '10'
		return_date['month'] = 'November' if return_date['month'] == '11'
		return_date['month'] = 'December' if return_date['month'] == '12'
		
		return return_date
	end # End of parse_date function.
	
	def ldap_search(attr,query)
		require "#{$pwd}/ldap_auth.rb"
 		# ldap_return auth (below) is a function from ldap_auth.rb that returns a
		# hash with the username and password to bind to LDAP with.
		ldap_auth = ldap_return_auth
		ldap = Net::LDAP.new
		ldap.host = 'ldap.oit.pdx.edu'
		ldap.port = 636
		ldap.auth ldap_auth['username'], ldap_auth['pass']
		ldap.encryption :method => :simple_tls
		ldap.base = 'dc=pdx,dc=edu'
		
		# Perform the search, then return a hash with LDAP attributes corresponding
		# to hash keys, and LDAP values corresponding to hash values.
		filter = Net::LDAP::Filter.eq(attr,query)
		result = Hash.new(Array.new)
		ldap.search(:filter => filter) do |entry|
			entry.each do |attribute, values|
				values.each do |value|
					result["#{attribute}"] += ["#{value}"]
					# This currently returns a hash like result[:dn] => 'blahblahblah'
				end
			end
		end
		return result
	end # End of ldap_search function

	def ldap_help(m)
		m.reply "LDAP Search"
		m.reply "==========="
		m.reply "Description: Performs a search on LDAP for the given query, then returns information about the user's account."
		m.reply "Usage: !ldap [username|email alias|email forwarding address]"
	end # End of ldap_help function.
	
	def help(m)
		m.reply "See: !help ldap"
	end

end
# End of plugin: LDAPsearch
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
