class LockOutTime
    include Cinch::Plugin
  
    require "#{$pwd}/lib/ldap_helper.rb"
    require "#{$pwd}/lib/util.rb"
  
    match(/locked (\w+)$/)
    match(/lockoutTime (\w+)$/)
  
    def execute(m, query)
    ldap = LdapHelper.new('cecs')
    util = Util.new

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
            result['lockouttime'].each do |time|
                if time.to_s == "0"
                    m.reply("Account is not locked")
                else
                    m.reply("Account has been locked since #{util.dos2unixtime(time)}")
                end
            end
        end
        m.reply(reply)
    end
  end

end
