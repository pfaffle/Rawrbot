# =============================================================================
# Plugin: USSCATldap
#
# Description:
#     Searches CAT LDAP for an account (!catldap)
#     and returns results about that query, if found.
#
# Requirements:
#        - The Ruby gem NET-LDAP.
#        - Server configuration and authentication information for NET-LDAP in the
#          file 'ldap.yml'.
#        - Rawrbot must be running on PSU's IP space (131.252.x.x). OIT's
#          authenticated LDAP directory (what rawrbot uses in this module) is
#          inaccessible otherwise.
class USSCATldap
    include Cinch::Plugin

    require 'net/ldap'
    require "#{$pwd}/lib/ldap_helper.rb"

    set :prefix, lambda { |m| m.bot.config.plugins.prefix }

    @@catldap = LdapHelper.load_from_yaml_file(
      LdapHelper::DEFAULT_CONFIG_FILE, 'cat'
    )
    @@oitldap = LdapHelper.load_from_yaml_file(
      LdapHelper::DEFAULT_CONFIG_FILE, 'oit'
    )

    match(/help catldap$/i, method: :catldap_help)
    match("help", method: :help)
    match(/catldap (\S+)$/i)

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
        
        # Determine what field to search and proceed to execute it.
        if (query =~ /@pdx\.edu/)
            type = 'email alias'
            attribute = 'mailLocalAddress'
        else
            type = 'username'
            attribute = 'uid'
        end

        # Execute the search.
        m.reply("Performing LDAP search on #{type} #{query}.")
        oit_result = @@oitldap.search(attribute,query)

        # Check for errors and abort early if detected.
        if !oit_result
            m.reply "Error: LDAP query failed. Check configuration.\n"
            return
        elsif oit_result.empty?
            User(m.user.nick).send("Error: No results.\n")
            return
        end

        # Iterate over each LDAP entry in the search result and print
        # forwarding information for each one.
	    reply << "ODIN uid: #{oit_result[0][:uid][0]}\n"
        oit_result.each do |oitEntry|
	        # Use OIT LDAP info to search CAT LDAP
	        if !oitEntry[:uniqueidentifier].empty?
	            attribute = 'uniqueidentifier'
	            query = oitEntry[:uniqueidentifier][0]
	            # Fix malformed uniqueids.
	            if query !~ /^P/i
	                query = "P" + query
	            end
	        else
	            attribute = 'oitusername'
                query = oitEntry[:uid][0]
	        end
	        cat_result = @@catldap.search(attribute,query)
	
	        # Check if we were able to find corresponding MCECS account.
	        if !cat_result
	            reply << "Error: LDAP subquery failed. Check configuration.\n"
            elsif cat_result.empty?
                reply << "No corresponding MCECS account found.\n"
	        else
                reply << "MCECS email forwards:\n"
                cat_result.each do |catEntry|
                    fwd = if catEntry[:mailroutingaddress].empty?
                        'n/a'
                    else
		                catEntry[:mailroutingaddress][0]
                          end
		            catEntry[:maillocaladdress].each do |email|
                        reply << " #{email} -> #{fwd}\n"
                    end
                end
	        end
        end

        # Send results via PM so as to not spam the channel.
        User(m.user.nick).send(reply)
    end

    # Help that is specific to the LDAP search function.
    def catldap_help(m)
        p = self.class.prefix.call(m)
        reply  = "CAT LDAP Search\n"
        reply += "===========\n"
        reply += "Description: Performs a search on CAT LDAP for the given query, "
        reply += "then returns information about the user's account.\n"
        reply += "Usage: #{p}catldap [username|email alias]"
        m.reply(reply)
    end

    # General help to point users to the more specific help functions.
    def help(m)
        p = self.class.prefix.call(m)
        m.reply("See: #{p}help catldap")
    end

end
