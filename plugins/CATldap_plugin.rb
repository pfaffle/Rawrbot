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
#          authenticated LDAP directory (what rawrbot uses in this module) is
#          inaccessible otherwise.
class CATldap
    include Cinch::Plugin

    self.prefix = lambda{ |m| /^#{m.bot.nick}/ }

    require 'net/ldap'
    require "#{$pwd}/lib/ldap_helper.rb"

    $catldap = LdapHelper.new('cat')
    $oitldap = LdapHelper.new('oit')

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
        cat_result = $catldap.search(attribute,query)

        # Check for errors.
        if (!cat_result)
            m.reply "Error: LDAP query failed. Check configuration."
        else
            if (cat_result['dn'].empty?)
                reply = "Error: No results.\n"
            elsif (cat_result['dn'].length > 1)
                reply = "Error: Too many results.\n"
            else
                # Piece together the final results and print them out in user-friendly output.
                cat_result['gecos'].each { |name| reply << "Name: #{name}\n" }
                cat_result['uid'].each { |uid| reply << "CAT uid: #{uid}\n" }
                if (cat_result['uniqueidentifier'].empty?)
                    reply << "OIT uid: no\n"
                else
                    uniqueid = cat_result['uniqueidentifier'][0]
                    # Fix malformed uniqueids.
                    if (!(uniqueid =~ /^P/i))
                        uniqueid = "P" + uniqueid
                    end
                    oit_result = $oitldap.search('uniqueidentifier',uniqueid)
                    if (!oit_result)
                        reply << "OIT subquery failed.\n"
                    else
                        oit_result['uid'].each { |uid| reply << "OIT uid: #{uid}\n" }
                        oit_result['roomnumber'].each { |room| reply << "Office: #{room}\n" }
                        oit_result['telephonenumber'].each { |phone| reply << "Phone: #{phone}\n" }
                        oit_result['ou'].each { |dept| reply << "Dept: #{dept}\n" }
                        oit_result['title'].each { |title| reply << "Title: #{title}\n" }
                    end
                end
            end
            # Send results via PM so as to not spam the channel.
            User(m.user.nick).send(reply)
        end
    end # End of execute function.



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

        cat_result = $catldap.search(attribute,query)
        reply = String.new()

        # Check for errors.
        if (!cat_result)
            reply = "Error: LDAP query failed. Check configuration."
        else
            if (cat_result['dn'].empty?)
                reply = "No results for #{query}.\n"
            elsif (cat_result['uniqueidentifier'].empty?)
                reply = "No phone number for #{query}.\n"
            elsif (cat_result['dn'].length > 1)
                reply = "Error: Too many results.\n"
            else
                # Piece together the final results and print them out in user-friendly output.
                uniqueid = cat_result['uniqueidentifier'][0]
                # Fix malformed uniqueids.
                if (!(uniqueid =~ /^P/i))
                    uniqueid = "P" + uniqueid
                end
                oit_result = $oitldap.search('uniqueidentifier',uniqueid)
                if (!oit_result)
                    reply << "OIT subquery failed.\n"
                else
                    if (oit_result['telephonenumber'].empty?)
                        reply = "No phone number for #{query}.\n"
                    else
                        oit_result['gecos'].each { |name| reply << "Name: #{name}    " }
                        oit_result['telephonenumber'].each { |phone| reply << "Phone: #{phone}    " }
                        oit_result['roomnumber'].each { |room| reply << "Office: #{room}" }
                    end
                end
            end
        end

        m.reply(reply)
        return
    end

    # Help that is specific to the LDAP search function.
    def ldap_help(m)
        reply  = "LDAP Search\n"
        reply += "===========\n"
        reply += "Description: Performs a search on LDAP for the given query, "
        reply += "then returns information about the user's account.\n"
        reply += "Usage: !ldap [username|email alias]"
        m.reply(reply)
    end

    # Help that is specific to the phone search function.
    def phone_help(m)
        reply  = "Phone Search\n"
        reply += "===========\n"
        reply += "Description: Searches LDAP for the given query, then returns "
        reply += "the user's phone number, if it exists in LDAP.\n"
        reply += "Usage: !phone [username|email alias]"
        m.reply(reply)
    end

    # General help to point users to the more specific help functions.
    def help(m)
        m.reply("See: !help ldap")
        m.reply("See: !help phone")
    end

end
