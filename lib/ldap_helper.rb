class LdapHelper

  require 'net/ldap'

  def initialize(provider)
    config_hash = YAML.load(File.read("config/ldap.yml"))
    @ldap = config_hash[provider]
  end

  def ldap_conn
    conn = Net::LDAP.new(
        { :host => @ldap['server'],
          :port => @ldap['port'],
          :auth =>
            { :method => :simple,
              :username => @ldap['username'],
              :password => @ldap['password'],
            },
          :encryption => ( @ldap['encryption'].to_sym if not @ldap['encryption'].nil?),
          :base       => @ldap['basedn'],
        } )
    return conn
  end

  def search(user, attributes, scope)
    output = []
    filter = Net::LDAP::Filter.eq( scope, user )

    attributes.each do | attribute |
      self.ldap_conn.search(:filter => filter) do |entry|
          output << entry[attribute]
      end
    end
    return output
  end

end
