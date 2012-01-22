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
		if m.message.match(/^#{m.bot.nick}[:,-]? (.+?) is (also )?(.+)/i)
			learn(m, $1, $3)
		elsif m.message.match(/^#{m.bot.nick}[:,-]? (.+) =~ s\/(.+)\/(.+)\//i)
			edit(m, $1, $2, $3)
		elsif m.message.match(/^#{m.bot.nick}[:,-]? forget (.+)/i)
			forget(m, $1)
		elsif m.message.match(/^#{m.bot.nick}[:,-]? literal (.+)/i)
			literal(m, $1)
		elsif m.message.match(/^#{m.bot.nick}[:,-]? ldap (.+)/i)
			# do nothing.
		elsif m.message.match(/^#{m.bot.nick}[:,-]? (.+)/i)
			teach(m, $1)
		elsif m.message.match(/^#{m.bot.nick}[:,-]?$/i)
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
