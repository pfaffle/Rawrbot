# =============================================================================
# Plugin: CATldap
#
# Description:
#     Searches LDAP for an account (!ldap) or a person's phone number (!phone), 
#     and returns results about that query, if found.
#
# Requirements:
#        - The Ruby gem NET-LDAP.
#        - Authentication information for NET-LDAP in the file 'auth_ldap.rb'.
#            The file must define a function named return_ldap_config which returns a
#            hash with two key->value pairs 'username' and 'pass', which rawrbot
#            will use to bind with OIT LDAP.
#        - Rawrbot must be running on PSU's IP space (131.252.x.x). OIT's
#         authenticated LDAP directory (what rawrbot uses in this module) is
#         inaccessible otherwise.
class CATldap
    include Cinch::Plugin
    
    self.prefix = lambda{ |m| /^#{m.bot.nick}/ }
    @@cat_configfile = "#{$pwd}/plugins/config/CATldap_config.rb"
    @@oit_configfile = "#{$pwd}/plugins/config/ldap_config.rb"

    require 'net/ldap'

    match(/^!help ldap/i, :use_prefix => false, method: :ldap_help)
    match(/^!help phone/i, :use_prefix => false, method: :phone_help)
    match("!help", :use_prefix => false, method: :help)
    match(/^!ldap (\S+)/i, :use_prefix => false)
    # The next line was helped out by:
    # http://stackoverflow.com/questions/406230/regular-expression-to-match-string-not-containing-a-word
    # This is meant to make rawrbot not trigger this module when someone attempts
    # to teach it about ldap with the learning module.
    match(/[:-]? ldap (((?!(.+)?is ).)+)/i)
    match(/^!phone (.+)/i, :use_prefix => false, method: :phone_search)

    # Function: execute
    #
    # Description: Parses the search query and executes a search on LDAP to retrieve
    # account information. Automatically decides what field of LDAP to search based
    # on what the query looks like. It then prints the results to the IRC user who
    # made the request.
    def execute(m, query)
        
        reply = String.new()
        
        # Error-checking to sanitize input. i.e. no illegal symbols.
        if (query =~ /[^\w@._-]/)
            m.reply("Invalid search query '#{query}'")
            return
        end    

        query.downcase!
        
        # Execute the search.
        type = 'username'
        attribute = 'uid'
        
        m.reply("Performing LDAP search on #{type} #{query}.")
        
        cat_search_result = ldap_search(attribute,query,@@cat_configfile)
        
        if (!cat_search_result)
            m.reply "Error: LDAP query failed. Check configuration."
        else
            #    Piece together the final results and print them out in user-friendly output.
            if (cat_search_result['dn'].empty?)
                reply = "Error: No results.\n"
            elsif (cat_search_result['dn'].length > 1)
                # Realistically this case should never happen because we filtered '*'
                # out of the search string earlier. If this comes up, something in LDAP
                # is really janky. The logic to account for this is here nonetheless,
                # just in case.
                reply = "Error: Too many results.\n"
            else
                #    Get name, username and dept of the user.
                cat_search_result['gecos'].each { |name| reply << "Name: #{name}\n" }
                cat_search_result['uid'].each { |uid| reply << "CAT uid: #{uid}\n" }
                if (cat_search_result['uniqueidentifier'].empty?)
                    reply << "OIT uid: no\n"
                else
                    uniqueid = cat_search_result['uniqueidentifier'][0]
                    if (!(uniqueid =~ /^P/i))
                        uniqueid = "P" + uniqueid
                    end
                    oit_search_result = ldap_search('uniqueidentifier',uniqueid,@@oit_configfile)
                    if (!oit_search_result)
                        reply << "OIT subquery failed.\n"
                    else
                        oit_search_result['uid'].each { |uid| reply << "OIT uid: #{uid}\n" }
                        oit_search_result['roomnumber'].each { |room| reply << "Office: #{room}\n" }
                        oit_search_result['telephonenumber'].each { |phone| reply << "Phone: #{phone}\n" }
                        oit_search_result['ou'].each { |dept| reply << "Dept: #{dept}\n" }
                        oit_search_result['title'].each { |title| reply << "Title: #{title}\n" }
                    end
                end

            end
            # Send results via PM so as to not spam the channel.
            User(m.user.nick).send(reply)
        end
    end # End of execute function.
    
    # Function: parse_date
    #
    # Description: Parses a String containing a date in Zulu time, and returns
    # it as a Time object.
    #
    # Arguments:
    # - A String, containing a date/time in Zulu time:
    #   yyyymmddhhmmssZ
    #
    # Returns:
    # - An instance of class Time, containing the date and time.
    def parse_date date
        unless date =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z/
            return nil
        end
        
        year = $1
        month = $2
        day = $3
        hour = $4
        min = $5
        sec = $6

        return Time.mktime(year, month, day, hour, min, sec)
    end # End of parse_date function.
    
    def ldap_search(attr,query,config)
        load config
    
        # return_ldap_config (below) is a function defined in the config file that returns a
        # hash with the settings to connect to to LDAP with.
        ldap_config = return_ldap_config()

        host = ldap_config[:server]
        port = ldap_config[:port]
         auth = { :method => :simple, :username => ldap_config[:username], :password => ldap_config[:pass] }
        base = ldap_config[:basedn]
    
        result = Hash.new(Array.new())
        Net::LDAP.open(:host => host, :port => port, :auth => auth, :encryption => :simple_tls, :base => base) do |ldap|
            
            # Perform the search, then return a hash with LDAP attributes corresponding
            # to hash keys, and LDAP values corresponding to hash values.
            filter = Net::LDAP::Filter.eq(attr,query)
            if ldap.bind()
                ldap.search(:filter => filter) do |entry|
                    entry.each do |attribute, values|
                        values.each do |value|
                            result["#{attribute}"] += ["#{value}"]
                        end
                    end
                end
            else
                result = false
            end
        end

        return result
    end # End of ldap_search function

    # Function: phone_search
    #
    # Description: Executes a search on LDAP for a person's username or email address to
    # retrieve a phone number. It then prints the results to the channel where the IRC
    # user made the request.
    def phone_search(m, query)

        # Error-checking to sanitize input. i.e. no illegal symbols.
        if (query =~ /[^\w@._-]/)
            m.reply("Invalid search query '#{query}'")
            return
        end    
        query.downcase!

        # Execute the search.
        attribute = 'uid'
        
        cat_search_result = ldap_search(attribute,query,@@cat_configfile)
        reply = String.new()
        
        if (!cat_search_result)
            reply = "Error: LDAP query failed. Check configuration."
        else
            #    Piece together the final results and print them out in user-friendly output.
            if (cat_search_result['dn'].empty?)
                reply = "No results for #{query}.\n"
            elsif (cat_search_result['uniqueidentifier'].empty?)
                reply = "No phone number for #{query}.\n"
            elsif (cat_search_result['dn'].length > 1)
                # Realistically this case should never happen because we filtered '*'
                # out of the search string earlier. If this comes up, something in LDAP
                # is really janky. The logic to account for this is here nonetheless,
                # just in case.
                reply = "Error: Too many results.\n"
            else
                #    Get name and phone of the user.
                uniqueid = cat_search_result['uniqueidentifier'][0]
                if (!(uniqueid =~ /^P/i))
                    uniqueid = "P" + uniqueid
                end
                oit_search_result = ldap_search('uniqueidentifier',uniqueid,@@oit_configfile)
                if (!oit_search_result)
                    reply << "OIT subquery failed.\n"
                else
                    if (oit_search_result['telephonenumber'].empty?)
                        reply = "No phone number for #{query}.\n"
                    else
                        oit_search_result['gecos'].each { |name| reply << "Name: #{name}    " }
                        oit_search_result['telephonenumber'].each { |phone| reply << "Phone: #{phone}    " }
                        oit_search_result['roomnumber'].each { |room| reply << "Office: #{room}" }
                    end
                end
            end
        end

        m.reply(reply)
        return
    end # End of phone_search function.

    def ldap_help(m)
        m.reply("LDAP Search")
        m.reply("===========")
        m.reply("Description: Performs a search on LDAP for the given query, then returns information about the user's account.")
        m.reply("Usage: !ldap [username|email alias]")
    end # End of ldap_help function.
    
    def phone_help(m)
        m.reply("Phone Search")
        m.reply("===========")
        m.reply("Description: Searches LDAP for the given query, then returns the user's phone number, if it exists in LDAP.")
        m.reply("Usage: !phone [username|email alias]")
    end # End of phone_help function.

    def help(m)
        m.reply("See: !help ldap")
        m.reply("See: !help phone")
    end # End of help function.

end
# End of plugin: LDAPsearch
# =============================================================================
