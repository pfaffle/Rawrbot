# =============================================================================
# Plugin: Social
#
# Description:
#     A friendly plugin, which makes the bot communicate with people who talk
#     to it.
#
# Requirements:
#     none
class Social
    include Cinch::Plugin

    match(/hello|hi|howdy|hey|greetings|sup|hola/i, :use_prefix => false, method: :greet)
    match(/(good)? ?(morning|afternoon|evening|night)/i, :use_prefix => false, method: :timeofday_greet)
    match(/(good)?bye|adios|farewell|later|see ?(ya|you|u)|cya/i, :use_prefix => false, method: :farewell)

    # Function: greet
    #
    # Description:
    #     Say hi!
    def greet(m)
        if m.message.match(/\b(hellos?|hi(ya)?|howdy|hey|greetings|yo|sup|hai|hola),? #{m.bot.nick}\b/i)
            greetings = ['Hello','Hi','Hola','Ni hao','Hey','Yo','Howdy']
            greeting = greetings[rand(greetings.size)]
            m.reply "#{greeting}, #{m.user.nick}!"
        end
    end # End of greet function
    
    # Function: timeofday_greet
    #
    # Description:
    #     Gives a time of day-specific response to a greeting. i.e. 'good morning'.
    def timeofday_greet(m)
        if m.message.match(/\b(good)? ?(morning|afternoon|evening|night),? #{m.bot.nick}\b/i)
            m.reply "Good #{$2.downcase}, #{m.user.nick}!"
        end
    end # End of timeofday_greet function

    # Function: farewell
    #
    # Description:
    #     Says farewell.
    def farewell(m)
        farewells = ['Bye','Adios','Farewell','Later','See ya','See you','Take care']
        farewell = farewells[rand(farewells.size)]
        if m.message.match(/\b((good)?bye|adios|farewell|later|see ?(ya|you|u)|cya),? #{m.bot.nick}\b/i)
            m.reply "#{farewell}, #{m.user.nick}!"
        end
    end
end
# End of plugin: Social
# =============================================================================
