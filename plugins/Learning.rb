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

  set(:prefix, ->(m) { m.bot.config.plugins.prefix })

  match(//, use_prefix: false)
  match('help', method: :help)
  match(/help learning/i, method: :learning_help)

  def initialize(m)
    super(m)
    @learning_db = nil
    init_db
  end

  # For testing
  def use_db(new_db)
    @learning_db = new_db if new_db
  end

  # Determines how to process the command, whether the user is trying to teach
  # the bot something, make the bot forget something, or retrieve information
  # from the bot.
  def execute(m)
    return unless bot_addressed?(m) && not_prefixed_command?(m)

    if message_without_bot_nick(m) =~ /(.+?) is (also )?(.+)/i
      learn(m, Regexp.last_match(1), Regexp.last_match(3))
    elsif message_without_bot_nick(m) =~ /(.+?) are (also )?(.+)/i
      learn(m, Regexp.last_match(1), Regexp.last_match(3))
    elsif message_without_bot_nick(m) =~ %r{(.+) =~ s/(.+)/(.*)/}i
      edit(m, Regexp.last_match(1), Regexp.last_match(2), Regexp.last_match(3))
    elsif message_without_bot_nick(m) =~ /forget (.+)/i
      forget(m, Regexp.last_match(1))
    elsif message_without_bot_nick(m) =~ /literal(ly)? (.+)/i
      literal(m, Regexp.last_match(2))
    elsif message_without_bot_nick(m) =~ /(.+)/i
      teach(m, Regexp.last_match(1))
    else
      respond(m)
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
    entry = @learning_db[topic]
    @learning_db[topic] = if entry.nil?
                            # entry does not yet exist in the db; insert it.
                            factoid
                          else
                            # entry already exists in the db; update it.
                            @learning_db[topic] = if factoid.start_with? '|'
                                                    "#{entry}#{factoid}"
                                                  else
                                                    "#{entry} or #{factoid}"
                                                  end
                          end
    m.reply(acknowledgement)
  end

  # Edits an existing entry by using regex syntax.
  def edit(m, topic, find, replace)
    entry = @learning_db[topic.downcase]
    if entry.nil?
      # Thing does not exist in the db; abort.
      m.reply("I don't know anything about #{topic}.")
      return
    end
    # Thing exists in the db; search for target string and update it.
    if entry.sub!(/#{find}/, replace).nil?
      m.reply("#{topic} doesn't contain '#{find}'.")
    else
      @learning_db[topic.downcase] = entry
      m.reply("done, #{m.user.nick}.")
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
    entry = @learning_db[topic.downcase]
    if entry.nil?
      # Thing does not exist in the db; abort.
      m.reply(give_up)
    else
      # If the entry contains pipe characters, split it into substrings
      # delimited by those pipe characters, then choose one randomly to spit
      # back out.
      if entry =~ /\|/
        split_entries = entry.split('|')
        entry = split_entries[rand(split_entries.size)]
      end

      # If the entry contains '$who', substitute all occurrences of that string
      # with the nick of the person querying rawrbot.
      entry.sub!(/\$who/i, usr) while entry =~ /\$who/i

      # If the entry contains the prefix <reply>, reply by simply saying
      # anything following it, rather than saying 'x is y'.
      if entry =~ /^<reply> ?(.+)/
        m.reply(max_reply_size(m, Regexp.last_match(1)))
        # If the entry contains the prefix <action>, send an action followed
        # by the entry
      elsif entry =~ /^<action> ?(.+)/
        m.action_reply(max_reply_size(m, Regexp.last_match(1)), 'ACTION')
      else
        m.reply(max_reply_size(m, "#{topic} is #{entry}."))
      end
    end
  end

  # Makes the bot forget whatever it knows about the given topic.
  def forget(m, topic)
    topic.strip!
    entry = @learning_db[topic.downcase]
    if entry.nil?
      m.reply("I don't know anything about #{topic}.")
    else
      @learning_db.delete(topic.downcase)
      m.reply("I forgot #{topic}.")
    end
  end

  # Displays the literal contents of the entry for the given topic,
  # without parsing special syntax like <reply>, <who>, and |.
  def literal(m, topic)
    entry = @learning_db[topic.downcase]
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
    reply = <<HELP
Learning module
===========
Description: Teach the bot about things, and have it repeat that info back later.
Usage: [botname] [thing] is [information] (to store additional [information]  under the keyword [thing].)
[botname] [thing] (to get whatever the bot knows about [thing].)
HELP
    m.reply(reply)
  end

  private

  def init_db
    return unless @learning_db.nil?
    @learning_db = KeyValueDatabase::SQLite.new('learning.sqlite3') do |config|
      config.table = 'learning'
      config.key_type = String
      config.value_type = String
    end
  end

  def bot_addressed?(m)
    !m.message.match(/^#{m.bot.nick}[:,-]?/i).nil? || m.channel.nil?
  end

  def not_prefixed_command?(m)
    m.message.match(m.bot.config.plugins.prefix).nil?
  end

  def message_without_bot_nick(m)
    return m.message.partition(Regexp.last_match(1))[2].lstrip if m.message =~ /^(#{m.bot.nick}[:,-]?)/i
    m.message
  end

  def max_reply_size(m, str, reply_type = 'PRIVMSG')
    str.split(/\r\n|\r|\n/).each do |line|
      maxlength = 510 - (':' + " #{reply_type} " + ' :').size
      maxlength = maxlength - m.bot.nick.length - 3 # size of '...'

      if line.bytesize > maxlength
        pos = line.rindex(/\s/, maxlength)
        r = pos || maxlength
        return line.slice!(0, r) + '...'
      end
      return line
    end
  end
end
