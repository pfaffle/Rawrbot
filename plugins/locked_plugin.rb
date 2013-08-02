class LockOutTime
  include Cinch::Plugin

  require File.expand_path('../../lib/util.rb', __FILE__)

  match(/!locked (\w+)/, :use_prefix => false)
  match(/!lockoutTime (\w+)/, :use_prefix => false)

  def execute(m, query)
    ldap = LdapHelper.new('cecs')
    util = Util.new
    attributes = ['lockoutTime']
    output = ldap.search(query, attributes, 'sAMAccountName')
    output.flatten!
    output.each { |time|
      if time.to_s == "0"
        m.reply("Account is not locked")
      else
        m.reply("Account has been locked since #{util.dos2unixtime(time)}")
      end
    }
  end

end
