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
            m.reply "Error: LDAP query failed. Check configuration.\n"
            return
        elsif (result.empty?)
            User(m.user.nick).send("Error: No results.\n")
            return
        end

        catEntry = result[0]
	    reply = "Home directory: #{catEntry[:homedirectory][0]}\n"
	    profile = catEntry[:profilepath][0].sub('\Windows Profile','')
	    reply += "Profile path: #{profile}\n"

        m.reply(reply)
    end
end
