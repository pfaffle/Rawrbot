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

  require 'sqlite3'

  @@learning_db = nil

  set :prefix, lambda {|m| m.bot.config.plugins.prefix}

  match //, :use_prefix => false
  match 'help', method: :help
  match /help learning/i, method: :learning_help

  def initialize(m)
    super(m)
    init_db
  end

  # For testing
  def use_db(new_db)
    @@learning_db = new_db if new_db
  end

  # Determines how to process the command, whether the user is trying to teach
  # the bot something, make the bot forget something, or retrieve information
  # from the bot.
  def execute(m)
    if is_bot_addressed?(m) && is_not_prefixed_command?(m)
      if message_without_bot_nick(m).match(/(.+?) is (also )?(.+)/i)
        learn(m, $1, $3)
      elsif message_without_bot_nick(m).match(/(.+?) are (also )?(.+)/i)
        learn(m, $1, $3)
      elsif message_without_bot_nick(m).match(/(.+) =~ s\/(.+)\/(.*)\//i)
        edit(m, $1, $2, $3)
      elsif message_without_bot_nick(m).match(/forget (.+)/i)
        forget(m, $1)
      elsif message_without_bot_nick(m).match(/literal(ly)? (.+)/i)
        literal(m, $2)
      elsif message_without_bot_nick(m).match(/(.+)/i)
        teach(m, $1)
      else
        respond(m)
      end
    end
  end

  # Makes the bot learn a factoid about the given topic.
  def learn(m, topic, factoid)
    usr = m.user.nick
    # TODO: make these configurable
    responses = ["good to know, #{usr}.", "got it, #{usr}.", "roger, #{usr}."]
    responses += ["understood, #{usr}.", "OK, #{usr}.", "so speaketh #{usr}."]
    responses += ["whatever you say, #{usr}."]
    responses += ["I'll take your word for it, #{usr}."]
    acknowledgement = responses[rand(responses.size)]
    topic.downcase!
    entry = @@learning_db[topic]
    if entry.nil?
      # entry does not yet exist in the db; insert it.
      @@learning_db[topic] = factoid
    else
      # entry already exists in the db; update it.
      if factoid.start_with? '|'
        @@learning_db[topic] = "#{entry}#{factoid}"
      else
        @@learning_db[topic] = "#{entry} or #{factoid}"
      end
    end
    m.reply(acknowledgement)
  end

  # Edits an existing entry by using regex syntax.
  def edit(m, topic, find, replace)
    entry = @@learning_db[topic.downcase]
    if entry.nil?
      # Thing does not exist in the db; abort.
      m.reply("I don't know anything about #{topic}.")
    else
      # Thing exists in the db; search for target string and update it.
      if entry.sub!(/#{find}/, replace).nil?
        m.reply("#{topic} doesn't contain '#{find}'.")
      else
        @@learning_db[topic.downcase] = entry
        m.reply("done, #{m.user.nick}.")
      end
    end
  end

  # Makes the bot teach the user what it knows about the given topic
  def teach(m, topic)
    usr = m.user.nick
    # TODO: make these configurable
    give_ups = ["bugger all, I dunno, #{usr}.", "no idea, #{usr}.", 'huh?']
    give_ups += ['what?', "dunno, #{usr}."]
    give_up = give_ups[rand(give_ups.size)]
    topic.strip!
    entry = @@learning_db[topic.downcase]
    if entry.nil?
      # Thing does not exist in the db; abort.
      m.reply(give_up)
    else
      # If the entry contains pipe characters, split it into substrings
      # delimited by those pipe characters, then choose one randomly to spit
      # back out.
      if entry.match(/\|/)
        split_entries = entry.split('|')
        entry = split_entries[rand(split_entries.size)]
      end

      # If the entry contains '$who', substitute all occurrences of that string
      # with the nick of the person querying rawrbot.
      while entry.match(/\$who/i)
        entry.sub!(/\$who/i, usr)
      end

      # If the entry contains the prefix <reply>, reply by simply saying
      # anything following it, rather than saying 'x is y'.
      if entry.match(/^<reply> ?(.+)/)
        m.reply($1)
        # If the entry contains the prefix <action>, send an action followed
        # by the entry
      elsif entry.match(/^<action> ?(.+)/)
        m.action_reply($1)
      else
        m.reply("#{topic} is #{entry}.")
      end
    end
  end

  # Makes the bot forget whatever it knows about the given topic.
  def forget(m, topic)
    topic.strip!
    entry = @@learning_db[topic.downcase]
    if entry.nil?
      m.reply("I don't know anything about #{topic}.")
    else
      @@learning_db.delete(topic.downcase)
      m.reply("I forgot #{topic}.")
    end
  end

  # Displays the literal contents of the entry for the given topic,
  # without parsing special syntax like <reply>, <who>, and |.
  def literal(m, topic)
    entry = @@learning_db[topic.downcase]
    if entry.nil?
      m.reply("No entry for #{topic}")
    else
      m.reply("#{topic} =is= #{entry}.")
    end
  end

  # If the bot is named but given no arguments, it responds with this function.
  def respond(m)
    responses = ["#{m.user.nick}?", 'yes?', 'you called?', 'what?']
    resp = responses[rand(responses.size)]
    m.reply(resp)
  end

  # Adds onto the generic help function for other plugins. Prompts people to use
  # a more specific command to get more details about the functionality of the
  # module specifically.
  def help(m)
    p = self.class.prefix.call(m)
    m.reply("See: #{p}help learning")
  end

  # Displays help information for how to use the plugin.
  def learning_help(m)
    reply = <<EOS
Learning module
===========
Description: Teach the bot about things, and have it repeat that info back later.
Usage: [botname] [thing] is [information] (to store additional [information]  under the keyword [thing].)
[botname] [thing] (to get whatever the bot knows about [thing].)
EOS
    m.reply(reply)
  end

  private

  def init_db
    return unless @@learning_db.nil?
    @@learning_db = KeyValueDatabase::SQLite.new('learning.sqlite3') do |config|
      config.table = 'learning'
      config.key_type = String
      config.value_type = String
    end
  end

  def is_bot_addressed?(m)
    !m.message.match(/^#{m.bot.nick}[:,-]?/i).nil? || m.channel.nil?
  end

  def is_not_prefixed_command?(m)
    m.message.match(m.bot.config.plugins.prefix).nil?
  end

  def message_without_bot_nick(m)
    if m.message.match(/^(#{m.bot.nick}[:,-]?)/i)
      return m.message.partition($1)[2].lstrip
    end
    m.message
  end
end
