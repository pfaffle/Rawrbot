# Plugin which performs a lookup on MCECS LDAP to find out what pods a user
# account is a member of, which determines its access to different Linux hosts.
class Pods
  include Cinch::Plugin

  require "#{$pwd}/lib/ldap_helper.rb"

  set(:prefix, ->(m) { m.bot.config.plugins.prefix })

  match(/pods (\w+)$/)

  def execute(m, query)
    ldap = LdapHelper.new('cat')

    # Error-checking to sanitize input. i.e. no illegal symbols.
    if query =~ /[^\w@._-]/
      m.reply("Invalid search query '#{query}'")
      return
    end
    reply = ''

    query.downcase!
    result = ldap.search('uid', query)

    # Check for errors.
    if !result
      m.reply "Error: LDAP query failed. Check configuration.\n"
      return
    elsif result.empty?
      User(m.user.nick).send("Error: No results.\n")
      return
    end

    cat_entry = result[0]
    cat_entry[:pod].each do |pod|
      reply += "#{pod} "
    end
    reply += "\n"

    m.reply(reply)
  end
end
