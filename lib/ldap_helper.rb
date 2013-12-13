class LdapHelper

    require 'net/ldap'
    require 'yaml'

    # Function: initialize
    #
    # Description:
    #   Constructs an LdapHelper object. Reads the ldap.yml config file and
    #   initializes the object to search for one particular LDAP server
    #   (provider) defined in that config file.
    # Arguments:
    #   The LDAP provider for this object to search.
    #
    # Returns:
    #   An LdapHelper object.
    def initialize(provider)
        configfile = YAML.load(File.read("config/ldap.yml"))
        @config = configfile[provider]
    end

    # Function: search
    #
    # Description:
    #   Connects to the LDAP server with the current configuration, then
    #   performs the specified search. Returns all results found.
    #
    # Arguments:
    #   - attr:   A string that specifies the attribute that you are
    #             searching by, e.g. uid.
    #   - query:  The value of the attribute that you are searching for.
    #
    # Returns:
    #   A Hash table containing keys which correspond with LDAP attributes,
    #   and values which correspond to the values of those attributes in the
    #   LDAP search results.
    def search(attr,query)
        # Get configuration ready.
        server = @config['server']
        port   = @config['port']
        auth   = { :method => :simple,
                   :username => @config['username'],
                   :password => @config['password']
                 }
        base   = @config['basedn']
        if (!@config['encryption'].nil?)
            encryption = @config['encryption'].to_sym
        end

        result = Net::LDAP::Entry.new()

        # Perform the search.
        Net::LDAP.open(:host => server, :port => port, :auth => auth,
                       :encryption => encryption, :base => base) do |ldap|
            if (!ldap.bind())
                result = false
            else
                filter = Net::LDAP::Filter.eq(attr,query)
                result = ldap.search(:filter => filter)
            end
        end

        return result
    end
    
    # Function: parse_date
    #
    # Description:
    #   Parses a String containing a date in Zulu time, and returns
    #   it as a Time object.
    #
    # Arguments:
    #   - A String, containing a date/time in Zulu time:
    #     yyyymmddhhmmssZ
    #
    # Returns:
    #   An instance of class Time, containing the date and time.
    def parse_date date
        unless date =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z/
            return nil
        end

        year = $1
        month = $2
        day = $3
        hour = $4
        min = $5
        sec = $6

        return Time.mktime(year, month, day, hour, min, sec)
    end
end
