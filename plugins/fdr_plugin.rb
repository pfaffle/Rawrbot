class Fdr
  include Cinch::Plugin

  require File.expand_path('../../lib/ldap_helper.rb', __FILE__)

  match(/!fdr (\w+)/, :use_prefix => false)

  def execute(m, query)
    ldap = LdapHelper.new('cecs')
    attributes = ['homedirectory', 'profilepath']
    output = ldap.search(query, attributes)
    output.flatten!
    output.each {|s| m.reply(s.to_s)}
  end

end
