class Fdr
    include Cinch::Plugin

    require "#{$pwd}/lib/ldap_helper.rb"

    match(/fdr (\w+)/)

    def execute(m, query)
        ldap = LdapHelper.new('cecs')
        # Error-checking to sanitize input. i.e. no illegal symbols.
        if (query =~ /[^\w@._-]/)
            m.reply("Invalid search query '#{query}'")
            return
        end
        reply = String.new()
    
        query.downcase!
        attributes = ['homedirectory', 'profilepath']
        result = ldap.search('sAMAccountName',query)
        reply = "Home directory: #{result['homedirectory'][0]}\n"
        reply += "Profile path: #{result['profilepath'][0]}\n"
        m.reply(reply)
    end
end
