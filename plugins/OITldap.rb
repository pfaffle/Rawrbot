# =============================================================================
# Plugin: OITLdap
#
# Description:
#     Searches LDAP for an account (!ldap) or a person's phone number (!phone),
#     and returns results about that query, if found.
#
# Requirements:
#        - The Ruby gem NET-LDAP.
#        - Server configuration and authentication information for NET-LDAP in
#          the file 'ldap.yml'.
#        - Rawrbot must be running on PSU's IP space (131.252.x.x). OIT's
#          authenticated LDAP directory (what rawrbot uses in this module) is
#          inaccessible otherwise.
class OITldap
    include Cinch::Plugin
    
    require 'net/ldap'
    require "#{$pwd}/lib/ldap_helper.rb"
    
    @@oitldap = LdapHelper.new('oit')

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
    # Description: Parses the search query and executes a search on LDAP to
    # retrieve account information. Automatically decides what field of LDAP
    # to search based on what the query looks like. It then prints the
    # results to the IRC user who made the request.
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
        m.reply("Performing LDAP search on #{type} #{query}.")
        result = @@oitldap.search(attribute,query)
        
        # Check for errors.
        if (!result)
            m.reply "Error: LDAP query failed. Check configuration.\n"
            return
        elsif (result.empty?)
            User(m.user.nick).send("Error: No results.\n")
            return
        end

        # Iterate over each LDAP entry in the search result and print
        # relevant information.
        result.each do |oitEntry|
            reply << "Name: #{oitEntry[:preferredcn][0]}\n"
            reply << "Username: #{oitEntry[:uid][0]}\n"
            reply << "Dept: #{oitEntry[:ou][0]}\n"
            
            # Determine if this is a sponsored account, and if so,
            # who the sponsor is.
            if (oitEntry[:psusponsorpidm].empty?)
                reply << "Sponsored: no\n"
            else
                # Look up sponsor's information.
                reply << "Sponsored: yes\n"
                sponsor_pidm = oitEntry[:psusponsorpidm][0]
                # Fix some malformed psusponsorpidms.
                if (!(sponsor_pidm =~ /^P/i))
                    sponsor_pidm = "P" + sponsor_pidm
                end
                
                sponsor = @@oitldap.search("uniqueIdentifier",sponsor_pidm)
            
                sponsor.each do |sponsorEntry|
                    sponsor_name = sponsorEntry[:gecos][0]
                    sponsor_uid = sponsorEntry[:uid][0]
                    reply << "Sponsor: #{sponsor_name} (#{sponsor_uid})\n"
                end
            end
        
            # Determine the account and password expiration dates. Also,
            # estimate the date the password was originally set by
            # subtracting 6 months from the expiration date.
            acctexp = @@oitldap.parse_date(oitEntry[:psuaccountexpiredate][0])
            reply << "Account expires: #{acctexp.asctime}\n"
            pwdexp = @@oitldap.parse_date(oitEntry[:psupasswordexpiredate][0])
            reply << "Password expires: #{pwdexp.asctime}\n"
            # Calculate the date/time that the password was set.
            day = 86400 # seconds
            pwdset = pwdexp - (180 * day)
            reply << "Password was set: #{pwdset.asctime}\n"

            # Print out any email aliases.
            oitEntry[:maillocaladdress].each do |mail|
                reply << "Email alias: #{mail}\n"
            end
        end

        # Send results via PM so as to not spam the channel.
        User(m.user.nick).send(reply)
    end
    
    # Function: phone_search
    #
    # Description: Executes a search on LDAP for a person's username or
    # email address to retrieve a phone number. It then prints the results
    # to the channel where the IRC user made the request.
    def phone_search(m, query)

        # Error-checking to sanitize input. i.e. no illegal symbols.
        if (query =~ /[^\w@._-]/)
            m.reply("Invalid search query '#{query}'")
            return
        end    
        query.downcase!

        # Determine what field to search and proceed to execute it.
        if (query =~ /@pdx\.edu/)
            attribute = 'mailLocalAddress'
        else
            attribute = 'uid'
        end
        
        result = @@oitldap.search(attribute,query)
        reply = String.new()
        
        # Check for errors.
        if (!result)
            m.reply "Error: LDAP query failed. Check configuration.\n"
            return
        elsif (result.empty?)
            User(m.user.nick).send("Error: No results.\n")
            return
        end

        # Format output.
        result.each do |entry|
            reply << "Name: #{entry[:preferredcn][0]}"
            if (entry[:telephonenumber].empty?)
                phone = 'n/a'
            else
                phone = entry[:telephonenumber][0]
            end
            reply << "    Phone: #{phone}\n"
        end

        m.reply(reply)
        return
    end # End of phone_search function.

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
