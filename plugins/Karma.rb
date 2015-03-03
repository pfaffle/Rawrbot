# ==============================================================================
# Karma Plugin
# ==============================================================================
#
# Tracks positive and negative karma for a given item. Increments karma when
# someone adds a ++ after a word (or a series of words encapsulated by
# parentheses) and decrements karma when someone adds -- to the same.
#
# Requirements:
# - The Ruby gem 'sqlite3' must be installed.
#
class Karma
  include Cinch::Plugin

  require 'sqlite3'

  @@karma_db = nil
  
  match(/\S+\+\+/, method: :increment, :use_prefix => false)
  match(/\S+--/, method: :decrement, :use_prefix => false)
  match(/karma (.+)/, method: :display)
  match(/help karma/i, method: :karma_help)
  match("help", method: :help)

  def initialize(m)
    super(m)
    @@karma_db = SQLite3::Database.new('karma.sqlite3')
    @@karma_db.execute("CREATE TABLE IF NOT EXISTS karma(
                          key TEXT PRIMARY KEY,
                          val INTEGER)")
  end

  # ============================================================================
  # Function: init_db
  # ============================================================================
  # 
  # Creates the sqlite database if it doesn't exist and inserts a table for
  # tracking karma.
  #
  def self.init_db()
    db = SQLite3::Database.new('karma.sqlite3')
    db.execute("CREATE TABLE IF NOT EXISTS karma(
                  key TEXT PRIMARY KEY,
                  val INTEGER)")
    return db
  end

  # ============================================================================
  # Function: increment
  # ============================================================================
  # 
  # Increments karma by one point for each object that has a ++ after it. If an
  # element reaches neutral (0) karma, it deletes it from the DB so the DB
  # doesn't grow any larger than it has to.
  #
  def increment(m)
    matches = m.message.scan(/\([^)]+\)\+\+|\S+\+\+/)

    # Iterate through each element to be incremented and do it.
    matches.each do |element|
      element.downcase!
      key = String.new()
      if (element =~ /\((.+)\)\+\+/)
        key = $1
      elsif (element =~ /(\S+)\+\+/)
        key = $1
      else
        break
      end

      r = @@karma_db.get_first_value("SELECT val FROM karma WHERE key=?", key)
      if (r != nil)
        # Element already exists in the db; update or delete it.
        if (r == -1)
          @@karma_db.execute("DELETE FROM karma WHERE key=?", key)
        else
          @@karma_db.execute("UPDATE karma SET val=? WHERE key=?", r+1, key)
        end
      else
        # Element does not yet exist in the db; insert it.
        @@karma_db.execute("INSERT INTO karma (key,val) VALUES (?,?)", key, 1)
      end
    end
  end
  
  # ============================================================================
  # Function: decrement
  # ============================================================================
  # 
  # Decrements karma by one point for each object that has a -- after it. If an
  # element reaches neutral (0) karma, it deletes it from the DB so the DB
  # doesn't grow any larger than it has to.
  #
  def decrement(m)
    matches = m.message.scan(/\([^)]+\)--|\S+--/)

    # Iterate through each element to be incremented and do it.
    matches.each do |element|
      element.downcase!
      key = String.new()
      if (element =~ /\((.+)\)--/)
        key = $1
      elsif (element =~ /(\S+)--/)
        key = $1
      else
        break
      end

      r = @@karma_db.get_first_value("SELECT val FROM karma WHERE key=?", key)
      if (r != nil)
        # Element already exists in the db; update or delete it.
        if (r == 1)
          @@karma_db.execute("DELETE FROM karma WHERE key=?", key)
        else
          @@karma_db.execute("UPDATE karma SET val=? WHERE key=?", r-1, key)
        end
      else
        # Element does not yet exist in the db; insert it.
        @@karma_db.execute("INSERT INTO karma (key,val) VALUES (?,?)", key, -1)
      end
    end
  end
  
  # ============================================================================
  # Function: display
  # ============================================================================
  #
  # Displays the current karma level of the requested element. If the element
  # does not exist in the DB, it has neutral (0) karma.
  #
  def display(m,key)
    key.downcase!
    r = @@karma_db.get_first_value("SELECT val FROM karma WHERE key=?", key)
    if (r != nil)
      m.reply("#{key} has karma of #{r}.")
    else
      m.reply("#{key} has neutral karma.")
    end
  end

  # ============================================================================
  # Function: karma_help
  # ============================================================================
  #
  # Displays help information for how to use the Karma plugin.
  #
  def karma_help(m)
    reply  = "Karma tracker\n"
    reply += "===========\n"
    reply += "Description: Tracks karma for things. Higher karma = liked more, "
    reply += "lower karma = disliked more.\n"
    reply += "Usage: !karma foo (to see karma level of 'foo')\n"
    reply += "foo++ (foo bar)++ increments karma for 'foo' and 'foo bar'\n"
    reply += "foo-- (foo bar)-- decrements karma for 'foo' and 'foo bar'"
    m.reply(reply)
  end
  
  # ============================================================================
  # Function: help
  # ============================================================================
  #
  # Adds onto the generic help function for other plugins. Prompts people to use
  # a more specific command to get more details about the functionality of the
  # Karma module specifically.
  #
  def help(m)
    m.reply("See: !help karma")
  end
end
