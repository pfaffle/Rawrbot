# Performs a lookup on MCECS AD domain controllers via LDAP to find the
# home directory and user profile directory for a given user account
class Fdr
  include Cinch::Plugin

  require "#{$pwd}/lib/ldap_helper.rb"

  set(:prefix, ->(m) { m.bot.config.plugins.prefix })

  match(/fdr (\w+)$/)

  def execute(m, query)
    ldap = LdapHelper.load_from_yaml_file(
      LdapHelper::DEFAULT_CONFIG_FILE, 'cecs'
    )
    # Error-checking to sanitize input. i.e. no illegal symbols.
    if query =~ /[^\w@._-]/
      m.reply("Invalid search query '#{query}'")
      return
    end

    query.downcase!
    result = ldap.search('sAMAccountName', query)

    # Check for errors.
    if !result
      m.reply "Error: LDAP query failed. Check configuration.\n"
      return
    elsif result.empty?
      User(m.user.nick).send("Error: No results.\n")
      return
    end

    cat_entry = result[0]
    reply = "Home directory: #{cat_entry[:homedirectory][0]}\n"
    profile = cat_entry[:profilepath][0].sub('\Windows Profile', '')
    reply += "Profile path: #{profile}\n"

    m.reply(reply)
  end
end
