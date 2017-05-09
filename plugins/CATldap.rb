# =============================================================================
# Plugin: CATldap
#
# Description:
#     Searches LDAP for an account (!ldap) or a person's phone number (!phone), 
#     and returns results about that query, if found.
#
# Requirements:
#        - The Ruby gem NET-LDAP.
#        - Server configuration and authentication information for NET-LDAP in the
#          file 'ldap.yml'.
#        - Rawrbot must be running on PSU's IP space (131.252.x.x). OIT's
#          LDAP directory (what rawrbot uses in this module) is inaccessible
#          otherwise.
class CATldap
    include Cinch::Plugin

    require 'net/ldap'
    require "#{$pwd}/lib/ldap_helper.rb"

    set :prefix, lambda { |m| m.bot.config.plugins.prefix }

    @@catldap = LdapHelper.load_from_yaml_file(
      LdapHelper::DEFAULT_CONFIG_FILE, 'cat')
    @@oitldap = LdapHelper.load_from_yaml_file(
      LdapHelper::DEFAULT_CONFIG_FILE, 'oit')

    match(/help ldap$/i, method: :ldap_help)
    match(/help phone$/i, method: :phone_help)
    match("help", method: :help)
    match(/ldap (\S+)$/i)
    # The next line was helped out by:
    # http://stackoverflow.com/questions/406230/regular-expression-to-match-string-not-containing-a-word
    # This is meant to make rawrbot not trigger this module when someone attempts
    # to teach it about ldap with the learning module.
    match(/[:-]? ldap (((?!(.+)?is ).)+)/i)
    match(/phone (.+)$/i, method: :phone_search)

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
        cat_result = @@catldap.search(attribute,query)

        # Check for errors.
        if (!cat_result)
            m.reply "Error: LDAP query failed. Check configuration.\n"
            return
        elsif (cat_result.empty?)
            User(m.user.nick).send("Error: No results.\n")
            return
        end

        # Iterate over each LDAP entry in the search result and print
        # relevant information.
        cat_result.each do |catEntry|
	        reply << "Name: #{catEntry[:gecos][0]}\n"
	        reply << "CAT uid: #{catEntry[:uid][0]}\n"
	        if (catEntry[:uniqueidentifier].empty?)
	            reply << "OIT uid: n/a\n"
	        else
	            uniqueid = catEntry[:uniqueidentifier][0]
	            # Fix malformed uniqueids.
	            if (!(uniqueid =~ /^P/i))
	                uniqueid = "P" + uniqueid
	            end
	            oit_result = @@oitldap.search('uniqueidentifier',uniqueid)
	            if (!oit_result)
	                reply << "OIT subquery failed.\n"
	            else
                    oit_result.each do |oitEntry|
		                reply << "OIT uid: #{oitEntry[:uid][0]}\n"
		                reply << "Office: #{oitEntry[:roomnumber][0]}\n"
		                reply << "Phone: #{oitEntry[:telephonenumber][0]}\n"
		                reply << "Dept: #{oitEntry[:ou][0]}\n"
		                reply << "Title: #{oitEntry[:title][0]}\n"
                    end
	            end
	        end
        end

        # Send results via PM so as to not spam the channel.
        User(m.user.nick).send(reply)
    end # End of execute function.



    # Function: phone_search
    #
    # Description: Executes a search on LDAP for a person's username or email
    # address to retrieve a phone number. It then prints the results to the
    # channel where the IRC user made the request.
    # 
    def phone_search(m, query)

        # Error-checking to sanitize input. i.e. no illegal symbols.
        if (query =~ /[^\w@._-]/)
            m.reply("Invalid search query '#{query}'")
            return
        end
        query.downcase!

        # Execute the search.
        attribute = 'uid'

        cat_result = @@catldap.search(attribute,query)
        reply = String.new()

        # Check for errors.
        if (!cat_result)
            m.reply "Error: LDAP query failed. Check configuration.\n"
            return
        elsif (cat_result.empty?)
            User(m.user.nick).send("Error: No results.\n")
            return
        end

        # Iterate over each LDAP entry in the search result and print
        # relevant information.
        cat_result.each do |catEntry|
            reply << "Name: #{catEntry[:gecos][0]}"
	        uniqueid = catEntry[:uniqueidentifier][0]
	        # Fix malformed uniqueids.
	        if (!(uniqueid =~ /^P/i))
	            uniqueid = "P" + uniqueid
	        end
	        oit_result = @@oitldap.search('uniqueidentifier',uniqueid)
	        if (!oit_result)
	            reply << "\nOIT subquery failed.\n"
            elsif (oit_result.empty?)
                reply << "\nNo corresponding OIT account found.\n"
	        else
	            oit_result.each do |oitEntry|
                    # Append phone number and office location if they
                    # exist in LDAP.
		            if (oitEntry[:telephonenumber].empty?)
		                phone = "n/a"
		            else
	                    phone = oitEntry[:telephonenumber][0]
                    end
                    if (oitEntry[:roomnumber].empty?)
                        room = "n/a"
                    else
	                    room = oitEntry[:roomnumber][0]
                    end
	                reply << "    Phone: #{phone}    Office: #{room}\n"
	            end
	        end
        end

        m.reply(reply)
        return
    end

    # Help that is specific to the LDAP search function.
    def ldap_help(m)
        p = self.class.prefix.call(m)
        reply  = "LDAP Search\n"
        reply += "===========\n"
        reply += "Description: Performs a search on LDAP for the given query, "
        reply += "then returns information about the user's account.\n"
        reply += "Usage: #{p}ldap [username|email alias]"
        m.reply(reply)
    end

    # Help that is specific to the phone search function.
    def phone_help(m)
        p = self.class.prefix.call(m)
        reply  = "Phone Search\n"
        reply += "===========\n"
        reply += "Description: Searches LDAP for the given query, then returns "
        reply += "the user's phone number, if it exists in LDAP.\n"
        reply += "Usage: #{p}phone [username|email alias]"
        m.reply(reply)
    end

    # General help to point users to the more specific help functions.
    def help(m)
        p = self.class.prefix.call(m)
        m.reply("See: #{p}help ldap")
        m.reply("See: #{p}help phone")
    end

end
