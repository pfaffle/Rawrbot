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
	        m.reply "Error: LDAP query failed. Check configuration.\n"
	        return
	    elsif (result.empty?)
	        User(m.user.nick).send("Error: No results.\n")
	        return
	    end
	
	    catEntry = result[0]
	    time = catEntry[:lockouttime][0]
	
	    if time.to_s == "0"
	        reply = "Account is not locked."
	    else
	        reply = "Account has been locked since #{util.dos2unixtime(time)}."
	    end

	    m.reply(reply)
    end
end
