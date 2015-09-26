class LdapHelper
  require 'net/ldap'
  require 'yaml'

  def initialize(provider)
    @config = load_config(provider)
  end

  def load_config(provider)
    config_file = YAML.load(File.read('config/ldap.yml'))[provider]
    {
      host: config_file['server'],
      port: config_file['port'],
      base: config_file['basedn'],
      encryption: config_file['encryption'].to_sym,
      auth: {
        method: :simple,
        username: config_file['username'],
        password: config_file['password']
      }
    }
  end

  def search(attribute, value)
    Net::LDAP.open(@config) do |ldap|
      fail "Unable to authenticate with LDAP server #{@config[:host]}" unless ldap.bind
      return ldap.search(filter: Net::LDAP::Filter.eq(attribute, value))
    end
  end
  
  # Takes a string in the format 'yyyymmddhhmmssZ' and makes a Time object.
  def parse_date(date)
    match = date.match(/(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z/)
    fail "Invalid date string format: #{date}" unless match
    Time.mktime(match[1], match[2], match[3],
                match[4], match[5], match[6])
  end
end
