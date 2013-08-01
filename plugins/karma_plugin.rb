# =============================================================================
# Plugin: Karma
#
# Description:
#     Tracks positive and negative karma for a given item. Increments
#     karma when someone adds a ++ after a word (or a series of words 
#     encapsulated by parentheses) and decrements karma when someone
#     adds -- to the same.
#
# Requirements:
#     The Ruby gem 'gdbm' must be installed.
class Karma
    include Cinch::Plugin
    
    require 'gdbm'
    @@karma_db = GDBM.new("#{$pwd}/karma.db", mode = 0600)
    
    match(/\S+\+\+/, method: :increment, :use_prefix => false)
    match(/\S+--/, method: :decrement, :use_prefix => false)
    match(/karma (.+)/, method: :display)
    match(/help karma/i, method: :karma_help)
    match("help", method: :help)

    # Function: increment
    #
    # Description: Increments karma by one point for each object
    # that has a ++ after it.
    #
    # Converts karma value to a Fixnum (int), adds 1, then converts back to
    # a String, because GDBM doesn't seem to like to store
    # anything but Strings. If an element reaches neutral (0) karma,
    # it deletes it from the DB so the DB doesn't grow any larger
    # than it has to.
    def increment(m)
        matches = m.message.scan(/\([^)]+\)\+\+|\S+\+\+/)
    
        matches.each do |element|
            element.downcase!
            if element =~ /\((.+)\)\+\+/
                if @@karma_db.has_key? $1
                    if @@karma_db[$1] == "-1"
                        @@karma_db.delete $1    
                    else
                        @@karma_db[$1] = (@@karma_db[$1].to_i + 1).to_s
                    end
                else
                    @@karma_db[$1] = "1"
                end
            elsif element =~ /(\S+)\+\+/
                if @@karma_db.has_key? $1
                    if @@karma_db[$1] == "-1"
                        @@karma_db.delete $1
                    else
                        @@karma_db[$1] = (@@karma_db[$1].to_i + 1).to_s
                    end
                else
                    @@karma_db[$1] = "1"
                end
            end
        end

    end # End of increment function
    
    # Function: decrement
    #
    # Description: Decrements karma by one point for each object
    # that has a -- after it.
    #
  # Converts karma value to a Fixnum (int), subtracts 1, then converts back to
    # a String, because GDBM doesn't seem to like to store
    # anything but Strings. If an element reaches neutral (0) karma,
    # it deletes it from the DB so the DB doesn't grow any larger
    # than it has to.
    def decrement(m)
        matches = m.message.scan(/\([^)]+\)--|\S+--/)
        
        matches.each do |element|
            element.downcase!
            if element =~ /\((.+)\)--/
                if @@karma_db.has_key? $1
                    if @@karma_db[$1] == "1"
                        @@karma_db.delete $1    
                    else
                        @@karma_db[$1] = (@@karma_db[$1].to_i - 1).to_s
                    end
                else
                    @@karma_db[$1] = "-1"
                end
            elsif element =~ /(\S+)--/
                if @@karma_db.has_key? $1
                    if @@karma_db[$1] == "1"
                        @@karma_db.delete $1    
                    else
                        @@karma_db[$1] = (@@karma_db[$1].to_i - 1).to_s
                    end
                else
                    @@karma_db[$1] = "-1"
                end
            end
        end

    end # End of decrement function
    
    # Function: display
    #
    # Description: Displays the current karma level of the requested element.
    #   If the element does not exist in the DB, it has neutral (0) karma.
    def display(m,arg)
        arg.downcase!
        if @@karma_db.has_key?("#{arg}")
            m.reply "#{arg} has karma of #{@@karma_db[arg]}."
        else
            m.reply "#{arg} has neutral karma."
        end
    end # End of display function

    # Function: karma_help
    #
    # Description: Displays help information for how to use the Karma plugin.
    def karma_help(m)
        m.reply "Karma tracker"
        m.reply "==========="
        m.reply "Description: Tracks karma for things. Higher karma = liked more, lower karma = disliked more."
        m.reply "Usage: !karma foo (to see karma level of 'foo')"
        m.reply "foo++ (foo bar)++ increments karma for 'foo' and 'foo bar'"
        m.reply "foo-- (foo bar)-- decrements karma for 'foo' and 'foo bar'"
    end
    
    # Function: help
    #
    # Description: Adds onto the generic help function for other plugins. Prompts
    #   people to use a more specific command to get more details about the
    #   functionality of the Karma module specifically.
    def help(m)
        m.reply "See: !help karma"
    end

end
# End of plugin: Karma
# =============================================================================
