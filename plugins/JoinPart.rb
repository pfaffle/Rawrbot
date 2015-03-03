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
    
    match(/join (#?\S+)( \S+)?/, method: :join)
    match(/part (#?\S+)( \S+)?/, method: :part)
    
    # Function: join
    #
    # Description:
    #     Joins a given channel.
    def join(m, chan, key = nil)
        chan = "#" + chan if (!chan.start_with? "#")
        key.lstrip! if (!key.nil?)
        Channel(chan).join(key)
        m.reply "Joining #{chan}."
    end
    
    # Function: part
    #
    # Description:
    #     Parts a given channel.
    def part(m, chan, msg = nil)
        chan = "#" + chan if (!chan.start_with? "#")
        msg.lstrip! if (!msg.nil?)
        m.reply "Leaving #{chan}."
        Channel(chan).part(msg)
    end
end
# End of plugin: JoinPart
# =============================================================================
