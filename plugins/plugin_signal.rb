# =============================================================================
# Plugin: Signal
#
# Description:
# 	Enables users to signal the bot owner to report an issue with the bot.
#
# Requirements:
#
class SendSignal
	include Cinch::Plugin
	
	require 'net/smtp'

	match("help", method: :help)
	match(/help signal/i, method: :signal_help)
	match(/\b(.+)signal (.+)\b$/i)
	
	def execute(m,tgt,msg)
		load "#{$pwd}/plugins/config_signal.rb"
		user_list = signal_return_config
		tgt.downcase!
		if user_list.has_key? tgt
			tgt_address = user_list[tgt]
			m.reply "Signaling #{tgt}..."
			Net::SMTP.start('mailhost.cecs.pdx.edu', 25) do |smtp|
				msgstr = "From: <#{m.user.nick}@irc\n"
				msgstr << "To: #{tgt} <#{tgt_address}>\n"
				msgstr << "Subject:\n"
				msgstr << "Date: #{Time.now}\n"
				msgstr << msg
				if (smtp.send_message msgstr, "#{m.user.nick}@irc", tgt_address)
					m.reply "Sent message \"#{msg}\" to #{tgt}."
				else
					m.reply "Failed to send message to #{tgt}."
				end
			end
		else
			reply = "No signaling available for #{tgt} yet."
			m.reply reply
			list_signals(m)
		end
	end

	# Function: help
	#
	# Description: Adds onto the generic help function for other plugins. Prompts
	#   people to use a more specific command to get more details about the
	#   functionality of the module specifically.
	def help(m)
		m.reply "See: !help signal"
	end # End of help function
	
	# Function: signal_help
	#
	# Description: Displays help information for how to use the plugin.
	def signal_help(m)
		m.reply "Signal"
		m.reply "==========="
		m.reply "Sends a text message to someone to report a problem. Don't abuse it!"
		m.reply "Usage: ![person]signal [your message]" 
		list_signals(m)
	end
	
	# Function: list_signals
	#
	# Description: Lists the people for whom signaling is available.
	def list_signals(m)
		load "#{$pwd}/plugins/config_signal.rb"
		user_list = signal_return_config
		reply = "Signaling is available for:"
		user_list.each do |person, address|
			reply << " #{person}"
		end
		m.reply reply
		m.reply "Talk to #{$owner} about adding others."
	end

end
# End of plugin: Signal
# =============================================================================
