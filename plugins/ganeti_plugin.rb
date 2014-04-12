class Ganeti
    include Cinch::Plugin
    require 'json/pure'
    require 'net/https'
    require 'uri'
    require 'yaml'

    match(/ganeti instance (\w+ \w+)$/, method: :instanceQuery)
    match(/ganeti help instance (\w+)$/, method: :helpInstance)

    def config
      YAML.load(File.read("config/ganeti.yml"))
    end

    def connectHttp
        uri = URI.parse("#{config['server']}:#{config['port']}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        return http
    end

    def querySplit(query)
      property = query.to_s.split(' ')[0]
      host     = query.to_s.split(' ')[1]
      return [property, host]
    end

    def helpInstance(m, query)
      config
      resp   = connectHttp.get("/#{config['api_version']}/instances/#{query}")
      parsed = JSON.parse(resp.body)
      m.reply("Available properties for #{query}are: #{parsed.keys}")
    end

    def instanceQuery(m, query)
      config
      host     = querySplit(query)[1]
      property = querySplit(query)[0]
      resp     = connectHttp.get("/#{config['api_version']}/instances/#{host}")
      parsed   = JSON.parse(resp.body)
      m.reply("#{property} for #{host}: #{parsed["#{property}"]}")
    end
end
