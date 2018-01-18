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

    set :prefix, lambda { |m| m.bot.config.plugins.prefix }

    ConfigFile = 'config/signal.yml'.freeze

    match("help", method: :help)
    match(/help signal/i, method: :signal_help)
    match(/\bsignal\s+(\S+)\s+(.+)\b$/i)
    match(/^\.(\S+)signal\s+(.+)$/i, :use_prefix => false)
    match(/^\.signal(\S+)\s+(.+)$/i, :use_prefix => false)
    
    def execute(m,tgt,msg)
        cfg = read_config(ConfigFile)
        userlist = Hash.new()

        # Enumerate signal targets.
        cfg['signals'].each { |k,v| userlist[k.downcase] = v } if cfg.has_key? 'signals'
        cfg['secret_signals'].each { |k,v| userlist[k.downcase] = v } if cfg.has_key? 'secret_signals'
        
        if userlist.has_key? tgt.downcase
            tgt_address = userlist[tgt.downcase]
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

    # Read in and validate the structure of the config file.
    def read_config(cfg)
        signals = YAML.safe_load(File.read(cfg))
        if !(signals.has_key?('signals') || signals.has_key?('secret_signals'))
            exc = "Please update SendSignal config file to the new format shown"
            exc << " in the samples directory."
            raise exc
        end
        return signals
    end

    # Function: help
    #
    # Description: Adds onto the generic help function for other plugins. Prompts
    #   people to use a more specific command to get more details about the
    #   functionality of the module specifically.
    def help(m)
        p = self.class.prefix.call(m)
        m.reply "See: #{p}help signal"
    end
    
    # Function: signal_help
    #
    # Description: Displays help information for how to use the plugin.
    def signal_help(m)
        p = self.class.prefix.call(m)
        m.reply "Signal"
        m.reply "==========="
        m.reply "Sends a text message to someone. Don't abuse it!"
        m.reply "Usage: #{p}signal [target] [message]" 
        list_signals(m)
    end
    
    # Function: list_signals
    #
    # Description: Lists the people for whom signaling is available.
    def list_signals(m)
        cfg = read_config(ConfigFile)
        if cfg.has_key? 'signals'
            userlist = cfg['signals']
            reply = "Signaling is available for:"
            userlist.each_key do |k|
                person = String.new(k)
                if person.length == 3
                    person[1] = '*'
                elsif person.length > 3 
                    person[2] = '*'
                end
                reply << " #{person}"
            end
            m.reply reply
        end
        m.reply "Ask a bot admin to add/remove signals."
    end

end
