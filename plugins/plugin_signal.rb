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
	match(/cmeinschsignal (.+)/i)
	
	def execute(m,msg)
		m.reply "Signaling cmeinsch..."
		Net::SMTP.start('mailhost.cecs.pdx.edu', 25) do |smtp|
			msgstr = "From: <#{m.user.nick}@irc\n"
			msgstr << "To: Craig <5037401262@txt.att.net>\n"
			msgstr << "Subject:\n"
			msgstr << "Date: #{Time.now}\n"
			msgstr << msg
			if (smtp.send_message msgstr, "#{m.user.nick}@irc", '5037401262@txt.att.net')
				m.reply "Sent message \"#{msg}\" to cmeinsch."
			else
				m.reply "Failed to send message to cmeinsch."
			end
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
		m.reply "Sends a text message to cmeinsch to report a problem with the bot."
		m.reply "cmeinsch gets free texts so feel free to use it, but don't abuse it!"
		m.reply "Usage: !cmeinschsignal [your message]" 
	end

end
# End of plugin: Signal
# =============================================================================
