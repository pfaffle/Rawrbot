class Reactions
  include Cinch::Plugin

  set :prefix, lambda { |m| m.bot.config.plugins.prefix }

  match //, :use_prefix => false

  def initialize(*args)
    super
    @reactions = YAML.safe_load(File.read("config/reactions.yml"))
  end

  def execute(m)
    @reactions.each do |trigger, response|
      if m.message =~ /#{trigger}/i
        m.reply(response)
      end
    end
  end
end
