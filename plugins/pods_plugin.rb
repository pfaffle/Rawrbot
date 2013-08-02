class Pods
  include Cinch::Plugin

  match(/!pods (\w+)/, :use_prefix => false)

  def execute(m, query)
    ldap = LdapHelper.new('cat')
    util = Util.new
    attributes = ['pod']
    pods = ldap.search(query, attributes, 'uid')
    pods.flatten!
    m.reply(pods.join(" "))
  end

end
