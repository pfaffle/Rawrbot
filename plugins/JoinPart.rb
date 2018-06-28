# =============================================================================
# Plugin: JoinPart
#
# Description:
#     Joins/parts a channel in response to a command.
#
# Requirements:
#     none
class JoinPart
  include Cinch::Plugin

  set(:prefix, ->(m) { m.bot.config.plugins.prefix })

  match(/join (#?\S+)( \S+)?/, method: :join)
  match(/part (#?\S+)( \S+)?/, method: :part)

  # Function: join
  #
  # Description:
  #     Joins a given channel.
  def join(m, chan, key = nil)
    chan = '#' + chan unless chan.start_with? '#'
    key.lstrip! unless key.nil?
    Channel(chan).join(key)
    m.reply "Joining #{chan}."
  end

  # Function: part
  #
  # Description:
  #     Parts a given channel.
  def part(m, chan, msg = nil)
    chan = '#' + chan unless chan.start_with? '#'
    msg.lstrip! unless msg.nil?
    m.reply "Leaving #{chan}."
    Channel(chan).part(msg)
  end
end
# End of plugin: JoinPart
# =============================================================================
