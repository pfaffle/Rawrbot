# A simple plugin which responds to a set of key words with programmed
# responses, defined in its config file.
class Reactions
  include Cinch::Plugin

  set(:prefix, ->(m) { m.bot.config.plugins.prefix })

  match(//, use_prefix: false)

  def initialize(*args)
    super
    @reactions = YAML.safe_load(File.read('config/reactions.yml'))
  end

  def execute(m)
    @reactions.each do |trigger, response|
      m.reply(response) if m.message =~ /#{trigger}/i
    end
  end
end
