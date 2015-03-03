# =============================================================================
# Plugin: Signal
#
# Description:
#     Enables users to signal the bot owner to report an issue with the bot.
#
# Requirements:
#
class SendSignal
    include Cinch::Plugin
    
    require 'net/smtp'
    require 'yaml'

    match("help", method: :help)
    match(/help signal/i, method: :signal_help)
    match(/\bsignal\s+(\S+)\s+(.+)\b$/i)
    match(/^\.(\S+)signal\s+(.+)$/i, :use_prefix => false)
    match(/^\.signal(\S+)\s+(.+)$/i, :use_prefix => false)
    
    def execute(m,tgt,msg)
        userlist = YAML.load(File.read("config/signal.yml"))
        tgt.downcase!
        if userlist.has_key? tgt
            tgt_address = userlist[tgt]
            m.reply "Signaling #{tgt}..."
            Net::SMTP.start('mailhost.cecs.pdx.edu', 25) do |smtp|
                msgstr = "From: #{m.user.nick}@irc <#{m.user.nick}@irc.cat.pdx.edu\n"
                msgstr << "To: #{tgt} <#{tgt_address}>\n"
                msgstr << "Subject:\n"
                msgstr << "Date: #{Time.now}\n"
                msgstr << msg
                if (smtp.send_message msgstr, "#{m.user.nick}@irc.cat.pdx.edu", tgt_address)
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
        m.reply "Sends a text message to someone. Don't abuse it!"
        m.reply "Usage: !signal [target] [message]" 
        list_signals(m)
    end
    
    # Function: list_signals
    #
    # Description: Lists the people for whom signaling is available.
    def list_signals(m)
        userlist = YAML.load(File.read("config/signal.yml"))
        reply = "Signaling is available for:"
        userlist.each do |person, address|
            mod_person = person.dup
            mod_person[rand(mod_person.length)] = '*'
            reply << " #{mod_person}"
        end
        m.reply reply
        m.reply "Ask a bot admin to add/remove signals."
    end

end
# End of plugin: Signal
# =============================================================================
