# =============================================================================
# Plugin: RTSearch
#
# Description:
#     Enables rawrbot to search OIT's Request Tracker ticketing system for basic
#     ticket data. This plugin simply notices when something appears like a ticket
#     number, then returns basic info about that ticket such as the Subject,
#     the Requestors, current Status, and Owner.
#
# Requirements:
#     A file 'config.rb' with authentication information for RT.
class RTSearch
    include Cinch::Plugin
    
    require 'net/http'
    require 'net/https'
    require 'yaml'

    set :prefix, lambda { |m| m.bot.config.plugins.prefix }

    match("help", method: :help)
    match(/help rtsearch|help rt/i, method: :rt_help)
    match(/(\d{1,6})/, :use_prefix => false)
    match(/rt reload$/i, method: :load_config)

    listen_to :connect, method: :quiet_load_config

    # Function: execute
    #
    # Description: Determines if a number is likely to be a ticket number,
    #     then calls the rt_search function to query RT for information about
    #     it. 
    def execute(m,tnumber)
        # Only perform ticket number searches in configured channels for
        # security purposes.
        if @@config['channels'].include? m.channel
            # The ticket_list hash is structured like so:
            # ticket_list["ticketnumber"] = verbose_flag
            ticket_list = Hash.new

            # Assemble a list of ticket numbers to search for.
            templist = m.message.scan(/(rt#|rt|#)?(\d{1,6})\b/i)
            if (!templist.nil?)
                # Filter out entries that are probably not ticket numbers.
                templist.each do |maybeticket|
                    if (maybeticket[0].nil?)
                        # Did not have a 'rt' and/or '#' prefix to the number.
                        # Don't be verbose with these.
                        if (maybeticket[1].size() == 6)
                            ticket_list["#{maybeticket[1]}"] = false
                        end
                    else
                        # Explicitly marked as a ticket number with "#" or "RT#".
                        # Be verbose if not a valid ticket.
                        if (maybeticket[1].size() < 7)
                            ticket_list["#{maybeticket[1]}"] = true
                        end
                    end
                end
            end
            if (ticket_list.size() > 0)
                rt_search m,ticket_list
            end
            # --- REMINDER: COMMENT 3 THREE LINES BELOW WHEN TESTING.
        elsif (m.message =~ /rt#\d{1,6}\b/i)
            m.reply "[RT] Ticket searches not allowed here."
        end
    end # End of execute function

    # Function: rt_search
    # 
    # Description: Perform the search on RT. Retrieve ticket number and basic
    #     ticket details.
    def rt_search(m,ticket_list)
        ticket = Hash.new
        # Format the HTTP request.
        http = Net::HTTP.new(@@config['server'],@@config['port'])
        if @@config['ssl']
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        login = "user=#{@@config['username']}&pass=#{@@config['pass']}"
        headers = { 'Content-Type' => 'application/x-www-form-urlencoded' }

        # Execute the HTTP requests.
        ticket_list.each do |tnumber,verbose|
            resp = http.post("#{@@config['baseurl']}/ticket/#{tnumber}/show",login,headers)
            data = resp.body
            if resp.is_a? Net::HTTPOK
                # If there is a '#' symbol immediately after RT's acknowledgement of the request,
                # it indicates an error message signifying that the ticket could not be displayed.
                if data =~ /^RT\/\d(\.\d+)+ 200 Ok\n\n#/
                    if verbose
                        m.reply "[RT] Ticket ##{tnumber} could not be displayed.\n"
                    end
                else
                # Parse the data retrieved about the ticket into a Hash variable.
                    data = data.split(/\n+/)
                    data.each do |element|
                        if element.match(/([^:]+): ?(.+)/)
                            ticket[$1] = $2
                        elsif element.match(/([^:]+):/)
                        ticket[$1] = ''
                        end
                    end
                    # Reply with ticket information.
                    m.reply "[RT] #{tnumber} | #{ticket['Requestors']} | #{ticket['Owner']} | #{ticket['Subject']}"
                end
            else
                m.reply "[RT] Error performing search. Please check config."
                break
            end
        end
    end # End of rt_search function

    # Function: quiet_load_config
    #
    # Description: Reloads configuration/authentication information used for
    #     interfacing with RT.
    def quiet_load_config(m)
        @@config = YAML.load(File.read("config/rt.yml"))
    end # End of quiet_load_config function

    # Function: load_config
    #
    # Description: Reloads configuration/authentication information used for
    #     interfacing with RT.
    def load_config(m)
        quiet_load_config(m)
        m.reply "RT config reloaded."
    end # End of load_config function

    # Function: help
    #
    # Description: Adds onto the generic help function for other plugins. Prompts
    #   people to use a more specific command to get more details about the
    #   functionality of the module specifically.
    def help(m)
        p = self.class.prefix.call(m)
        m.reply "See: #{p}help rtsearch"
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
