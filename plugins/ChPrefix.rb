class ChPrefix
  include Cinch::Plugin

  set :prefix, lambda { |m| m.bot.config.plugins.prefix }

  match 'prefix'
  match /chprefix (\S)/, :method => :chprefix

  def execute(m)
    m.reply "prefix: #{self.class.prefix.call(m)}"
  end

  def chprefix(m, newprefix)
    m.reply "changing prefix to #{newprefix}"
    @bot.config.plugins.prefix = newprefix
  end

end
