class Ganeti
    include Cinch::Plugin
    require 'json/pure'
    require 'net/https'
    require 'uri'
    require 'yaml'

    match(/ganeti (\w+ \w+ \w+)$/, method: :ganetiQuery)

    def config
      YAML.load(File.read("config/ganeti.yml"))
    end

    def connectHttp
      uri              = URI.parse("#{config['server']}:#{config['port']}")
      http             = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl     = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      return http
    end

    def gArg(query)
      h = Hash.new
      h['type']     = query.to_s.split(' ')[0]
      h['host']     = query.to_s.split(' ')[1]
      h['property'] = query.to_s.split(' ')[2]
      h['type']     = pluralize(h['type'])
      return h
    end

    def validHost?(host, type)
      resp   = connectHttp.get("/#{config['api_version']}/#{type}")
      parsed = JSON.parse(resp.body)
      parsed.each do |hash|
        if hash['id'] =~ /#{host}.*.pdx.edu/
          return true
        end
      end
      return false
    end

    def pluralize(string)
      if string[-1, 1] != 's'
        return string + 's'
      else
        return string
      end
    end

    def ganetiQuery(m, query)
      config
      host     = gArg(query)['host']
      property = gArg(query)['property']
      type     = gArg(query)['type']

      if validHost?(host, type)
        resp     = connectHttp.get("/#{config['api_version']}/#{type}/#{host}")
        parsed   = JSON.parse(resp.body)

        if resp.code !~ /2[0-9][0-9]/
          m.reply("HTTP error #{resp.code}!")
        else
          m.reply("#{property} for #{host}: #{parsed["#{property}"]}")
        end
      else
        m.reply("#{host} is not a valid host.")
      end
    end
end
