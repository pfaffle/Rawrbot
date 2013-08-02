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
#          :encryption => :simple_tls,
          :base       => @ldap['basedn'],
        } )
    return conn
  end

  def search(user, attributes)
    output = []
    filter = Net::LDAP::Filter.eq( "cn", user )

    attributes.each do | attribute |
      self.ldap_conn.search(:filter => filter) do |entry|
          output << entry[attribute]
      end
    end
    return output
  end

end
