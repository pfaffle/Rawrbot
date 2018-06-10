require 'net/ldap'
require 'yaml'

class LdapHelper
  DEFAULT_CONFIG_FILE = 'config/ldap.yml'.freeze

  def initialize(config)
    @config = config.dup
    @config['basedn'] ||= ''
    validate_config
  end

  def self.load_from_yaml_file(path, key)
    LdapHelper.new(YAML.safe_load(File.read(path))[key])
  end

  def search(attribute, query_string)
    server.search(:filter => Net::LDAP::Filter.eq(attribute, query_string))
  end

  def bind
    server.bind
  end

  def parse_date(date)
    match = date =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z/
    return nil unless match
    Time.mktime(match[0], match[1], match[2], match[3], match[4], match[5])
  end

  private

  def encryption
    return nil unless @config['encryption']
    :simple_tls
  end

  def server
    Net::LDAP.new(
      :host => @config['server'],
      :port => @config['port'],
      :auth => auth,
      :encryption => encryption,
      :base => @config['basedn']
    )
  end

  def auth
    if @config['username'].nil?
      { method: :anonymous }
    else
      {
        method: :simple,
        username: @config['username'],
        password: @config['password']
      }
    end
  end

  def validate_config
    %w(server port).each do |key|
      raise "Missing required LDAP config param: #{key}" if @config[key].nil?
    end
  end
end
