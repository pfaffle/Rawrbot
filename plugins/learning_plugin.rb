# ==============================================================================
# Learning Plugin
# ==============================================================================
#
# Enables the bot to be taught about various topics/things. Stored as a simple
# key-value pairing. When new information is added to a topic that the bot
# already knows about, the bot appends it to the end of the entry and separates
# it with "or". For example:
#
# bar => a place to get drinks or a chunk of metal
#
# Requirements:
# - The Ruby gem 'sqlite3' must be installed.
#
class Learning
  include Cinch::Plugin

  self.prefix = lambda{ |m| /^#{m.bot.nick}/ } 

  require 'sqlite3'
 
  @@learning_db = nil

  match(/[:,-]?/)
  match("!help", :use_prefix => false, method: :help)
  match(/^!help learning/i, :use_prefix => false, method: :learning_help)

  def initialize(m)
    super(m)
    @@learning_db = SQLite3::Database.new('learning.sqlite3')
    @@learning_db.execute("CREATE TABLE IF NOT EXISTS learning(
                          key TEXT PRIMARY KEY,
                          val TEXT)")
  end

  # ============================================================================
  # Function: execute
  # ============================================================================
  #
  # Determines how to process the command, whether the user is trying to teach
  # the bot something, make the bot forget something, or retrieve information
  # from the bot.
  #
  def execute(m)
    if (m.message.match(/^#{m.bot.nick}[:,-]? (.+?) is (also )?(.+)/i))
      learn(m, $1, $3)
    elsif (m.message.match(/^#{m.bot.nick}[:,-]? (.+) =~ s\/(.+)\/(.*)\//i))
      edit(m, $1, $2, $3)
    elsif (m.message.match(/^#{m.bot.nick}[:,-]? forget (.+)/i))
      forget(m, $1)
    elsif (m.message.match(/^#{m.bot.nick}[:,-]? literal (.+)/i))
      literal(m, $1)
    elsif (m.message.match(/^#{m.bot.nick}[:,-]? ldap (.+)/i))
      # do nothing.
    elsif (m.message.match(/^#{m.bot.nick}[:,-]? (.+)/i))
      teach(m, $1)
    elsif (m.message.match(/^#{m.bot.nick}[:,-]? ?$/i))
      address(m)
    end
  end

  # ============================================================================
  # Function: learn
  # ============================================================================
  #
  # Makes the bot learn something about the given thing. Stores it in the
  # learning database.
  #
  def learn(m, key, val)
    usr = m.user.nick
    responses  = ["good to know, #{usr}.","got it, #{usr}.","roger, #{usr}."]
    responses += ["understood, #{usr}.","OK, #{usr}.","so speaketh #{usr}."]
    responses += ["whatever you say, #{usr}."]
    responses += ["I'll take your word for it, #{usr}."]
    resp = responses[rand(responses.size)]
    key.downcase!
    r = @@learning_db.get_first_value("SELECT val FROM learning WHERE key=?",
                                      key)
    if (r != nil)
      # key already exists in the db; update it.
      @@learning_db.execute("UPDATE learning SET val=? WHERE key=?",
                            "#{r} or #{val}",
                            key)
    else
      # key does not yet exist in the db; insert it.
      @@learning_db.execute("INSERT INTO learning (key,val) VALUES (?,?)",
                            key,
                            val)
    end
    m.reply(resp)
  end

  # ============================================================================
  # Function: edit
  # ============================================================================
  #
  # Edits an existing entry in the database by using regex syntax.
  #
  def edit(m, key, find, replace)
    r = @@learning_db.get_first_value("SELECT val FROM learning WHERE key=?",
                                      key.downcase)
    if (r != nil)
      # Thing exists in the db; search for target string and update it.
      if (r.sub!(/#{find}/,replace).nil?)
        m.reply("#{key} doesn't contain '#{find}'.")
      else
        @@learning_db.execute("UPDATE learning SET val=? WHERE key=?",
                              r,
                              key)
        m.reply("done, #{m.user.nick}.")
      end
    else
      # Thing does not exist in the db; abort.
      m.reply("I don't know anything about #{key}.")
    end
  end

  # ============================================================================
  # Function: teach
  # ============================================================================
  #
  # Makes the bot teach the user what it knows about the given thing, as it is
  # stored in the database.
  #
  def teach(m, key)
    usr = m.user.nick
    giveups  = ["bugger all, I dunno, #{usr}.","no idea, #{usr}.","huh?"]
    giveups += ["what?","dunno, #{usr}."]
    giveup = giveups[rand(giveups.size)]
    r = @@learning_db.get_first_value("SELECT val FROM learning WHERE key=?",
                                      key.downcase)
    if (r != nil)
      # If the entry contains pipe characters, split it into substrings delimited
      # by those pipe characters, then choose one randomly to spit back out.
      if (r.match(/\|/))
        split_entries = r.split('|')
        r = split_entries[rand(split_entries.size)]
      end
      
      # If the entry contatins '$who', substitute all occurrences of that string
      # with the nick of the person querying rawrbot.
      while (r.match(/\$who/i))
        r.sub!(/\$who/i,"#{usr}")
      end
      
      # If the entry contains the prefix <reply>, reply by simply saying
      # anything following it, rather than saying 'x is y'.
      if (r.match(/^<reply> ?(.+)/))
        m.reply($1)
      else
        m.reply("#{key} is #{r}.")
      end
      
    else
      # Thing does not exist in the db; abort.
      m.reply(giveup)
    end
  end

  # ============================================================================
  # Function: forget
  # ============================================================================
  #
  # Makes the bot forget whatever it knows about the given thing. Removes that
  # key from the database.
  #
  def forget(m, key)
    r = @@learning_db.get_first_value("SELECT val FROM learning WHERE key=?",
                                      key.downcase)
    if (r != nil)
      @@learning_db.execute("DELETE FROM learning WHERE key=?",key.downcase)
      m.reply("I forgot #{key}.")
    else
      m.reply("I don't know anything about #{key}.")
    end
  end

  # ============================================================================
  # Function: literal
  # ============================================================================
  #
  # Displays the literal contents of the database entry for the given thing,
  # without parsing special syntax like <reply> and |.
  #
  def literal(m, key)
    r = @@learning_db.get_first_value("SELECT val FROM learning WHERE key=?",
                                      key.downcase)
    if (r != nil)
      m.reply("#{key} =is= #{r}.")
    else
      m.reply("No entry for #{key}")
    end
  end

  # ============================================================================
  # Function: address
  # ============================================================================
  #
  # If the bot is named but given no arguments, it responds with this function.
  #
  def address(m)
    responses = ["#{m.user.nick}?",'yes?','you called?','what?']
    resp = responses[rand(responses.size)]
    m.reply(resp)
  end

  # ============================================================================
  # Function: help
  # ============================================================================
  #
  # Adds onto the generic help function for other plugins. Prompts people to use
  # a more specific command to get more details about the functionality of the
  # module specifically.
  #
  def help(m)
    m.reply("See: !help learning")
  end
  
  # ============================================================================
  # Function: learning_help
  # ============================================================================
  #
  # Displays help information for how to use the plugin.
  #
  def learning_help(m)
    reply  = "Learning module\n"
    reply += "===========\n"
    reply += "Description: Teach the bot about things, and have it repeat that "
    reply += "info back later.\n"
    reply += "Usage: [botname] [thing] is [information] (to store additional "
    reply += "[information]  under the keyword [thing].)\n"
    reply += "[botname] [thing] (to get whatever the bot knows about [thing].)"
    m.reply(reply)
  end
end
