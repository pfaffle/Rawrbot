class Fdr
    include Cinch::Plugin

    require "#{$pwd}/lib/ldap_helper.rb"

    match(/fdr (\w+)$/)

    def execute(m, query)
        ldap = LdapHelper.new('cecs')
        # Error-checking to sanitize input. i.e. no illegal symbols.
        if (query =~ /[^\w@._-]/)
            m.reply("Invalid search query '#{query}'")
            return
        end
        reply = String.new()
    
        query.downcase!
        result = ldap.search('sAMAccountName',query)

        # Check for errors.
        if (!result)
            m.reply "Error: LDAP query failed. Check configuration."
        else
            if (result['dn'].empty?)
                reply = "Error: No results.\n"
            elsif (result['dn'].length > 1)
                reply = "Error: Too many results.\n"
            else
                reply = "Home directory: #{result['homedirectory'][0]}\n"
                profile = result['profilepath'][0].sub('\Windows Profile','')
                reply += "Profile path: #{profile}\n"
            end
            m.reply(reply)
        end
    end
end
