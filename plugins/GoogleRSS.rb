# =============================================================================
# Plugin: Google RSS Feed
#
# Description:
#        Collects information from the Google Apps Status Dashboard
#        RSS feed, then reports it to an IRC channel to alert users
#        of outages.
#
# Requirements:
#     The Ruby gem 'sanitize' must be installed. (version 2.0.3)
#
class GoogleRSS
    include Cinch::Plugin
    
    @@active = false

    require 'sanitize'
    require 'yaml'
    require 'rss/1.0'
    require 'rss/2.0'

    set :prefix, lambda { |m| m.bot.config.plugins.prefix }

    match /rss on$/i, method: :start_ticker
    match /rss off$/i, method: :stop_ticker
    match /rss restart$/i, method: :restart_ticker
    match /rss$/i, method: :report_status
    match /help$/i, method: :help
    match /help (google|rss)$/i, method: :google_help

    listen_to :connect, method: :quiet_start_ticker

    # Function: start_ticker
    #
    # Description:
    #     Start up the ticker and let people know that it's happening.
    def start_ticker(m)
        quiet_start_ticker(m)
        m.reply "Google RSS: On"
    end

    # Function: quiet_start_ticker
    #
    # Description:
    #     Start up the ticker silently.
    def quiet_start_ticker(m)
        if !@@active
            @@active = true
            @@thread = Thread.new {run_ticker(m)}
        end
    end

    # Function: stop_ticker
    #
    # Description:
    #     Stop the ticker and let people know that it's off.
    def stop_ticker(m)
        quiet_stop_ticker(m)
        m.reply "Google RSS: Off"
    end

    # Function: quiet_stop_ticker
    #
    # Description:
    #     Stop the ticker silently.
    def quiet_stop_ticker(m)
        @@active = false
        @@thread.kill
    end

    # Function: restart_ticker
    #
    # Description:
    #     Stop and restart the ticker. Good for reloading an edited
    #     configuration file.
    def restart_ticker(m)
        quiet_stop_ticker(m)
        quiet_start_ticker(m)
        m.reply "Google RSS: Restarted"
    end

    # Function: report_status
    #
    # Description: Notifies the user/channel of the current status of
    #     the Google RSS ticker.
    def report_status(m)
        if @@active
            m.reply "Google RSS: On"
        else
            m.reply "Google RSS: Off"
        end
    end

    # Function: run_ticker
    #
    # Description: Retrieves the current RSS data from Google Apps
    #     Status tracker, then begins monitoring it for changes. Reports
    #     updates when they appear.
    def run_ticker(m)
        config = YAML.safe_load(File.read("config/google.yml"))
        source = "http://www.google.com/appsstatus/rss/en"
        current_msg = String.new
        
        # Get current RSS message without reporting it.
        raw = String.new
        open(source) do |input|
            raw = input.read
        end
        rss = RSS::Parser.parse(raw, false)

        if !rss.items.empty?
            current_msg = rss.items[0].description
        end

        # Begin checking for new RSS messages.
        while @@active
            sleep(config['frequency'])

            raw = String.new
            open(source) do |input|
                raw = input.read
            end
            rss = RSS::Parser.parse(raw, false)

            # If there are any entries in the RSS feed, check if they
            # are different from what we already have. If so, update, then
            # print them out.
            if !rss.items.empty?
                if (rss.items[0].description != current_msg)
                    current_msg = rss.items[0].description

                    cleaned_rss = Sanitize.clean(rss.items[0].description)
                    # Google has an interesting way of dividing up different entries...
                    # with the following Unicode character delimiter.
                    msg_set = cleaned_rss.split "\u00A0"
                    msg_set.each { |msg| msg.strip! }
                    msg_set.delete_if { |msg| msg.empty? }
    
                    reply = "[#{rss.items[0].title}] "
                    reply << (msg_set[0]).to_s
                    
                    # Report RSS results to each channel in the list.
                    config['channels'].each do |chname|
                        max_msg_size = 512 - m.bot.nick.size - chname.size - 43
                        Channel(chname).send reply[0,max_msg_size]
                        Channel(chname).send "More info at: #{rss.items[0].link}"
                    end

                end
            end
        end

    end
    
    # Function: google_help
    #
    # Description: Displays help information for how to use the Google plugin.
    def google_help(m)
        p = self.class.prefix.call(m)
        reply = "Google Apps Status RSS feed\n"
        reply << "===========\n"
        reply << "Description: Periodically checks the Google Apps Status RSS "
      reply << "feed and report any outages and when they are resolved.\n"
        reply << "Usage:\n"
        reply << " #{p}rss on (to start reporting)\n"
        reply << " #{p}rss off (to disable reporting)\n"
        reply << " #{p}rss restart (to restart reporting, or reload a new config)\n"
        m.reply reply
    end

    # Function: help
    #
    # Description: Adds onto the generic help function for other plugins. Prompts
    #   people to use a more specific command to get more details about the
    #   functionality of this module specifically.
    def help(m)
        p = self.class.prefix.call(m)
        m.reply "See: #{p}help google"
    end

end
