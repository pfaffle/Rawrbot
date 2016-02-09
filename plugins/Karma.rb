# Tracks positive and negative karma for a given item. Increments karma when
# someone adds a ++ after a word (or a series of words encapsulated by
# parentheses) and decrements karma when someone adds -- to the same.
#
# Requirements:
# - The Ruby gem 'sqlite3' must be installed.
#
# noinspection RubyClassVariableUsageInspection
class Karma
  include Cinch::Plugin

  require 'lib/key_value_db'
  set :prefix, lambda { |m| m.bot.config.plugins.prefix }

  @@karma_db = nil

  match(/\S+\+\+/, method: :increment_all, :use_prefix => false)
  match(/\S+--/, method: :decrement_all, :use_prefix => false)
  match(/karma (.+)/, method: :display_karma)
  match(/help karma/i, method: :karma_help)
  match('help', method: :help)

  def initialize(m)
    super
    init_db
  end

  # For testing
  def use_db(new_db)
    @@karma_db = new_db if new_db
  end

  # Increments karma by one point for each element that has a ++ after it. If
  # an element reaches neutral (0) karma, it is deleted from the DB so the DB
  # doesn't grow any larger than it has to.
  def increment_all(m)
    m.message.scan(/\([^)]+\)\+\+|\S+\+\+/).each do |element|
      increment(element)
    end
  end

  # Decrements karma by one point for each element that has a -- after it. If
  # an element reaches neutral (0) karma, it is deleted from the DB so the DB
  # doesn't grow any larger than it has to.
  def decrement_all(m)
    m.message.scan(/\([^)]+\)--|\S+--/).each do |element|
      decrement(element)
    end
  end

  # Displays the current karma level of the requested element. If the element
  # does not exist in the DB, it has neutral (0) karma.
  def display_karma(m, key)
    key.downcase!
    key.strip!
    karma_value = @@karma_db[key]
    if !karma_value.nil?
      m.reply("#{key} has karma of #{karma_value}.")
    else
      m.reply("#{key} has neutral karma.")
    end
  end

  # Displays help information for how to use the Karma plugin.
  def karma_help(m)
    p = self.class.prefix.call(m)
    msg = <<EOS
Karma tracker
===========
Description: Tracks karma for things. Higher karma = liked more, lower karma = disliked more.
Usage: #{p}karma foo (to see karma level of 'foo')
foo++ (foo bar)++ increments karma for 'foo' and 'foo bar'
foo-- (foo bar)-- decrements karma for 'foo' and 'foo bar'
EOS
    m.reply(msg)
  end

  # Adds onto the generic help function for other plugins. Prompts people to use
  # a more specific command to get more details about the functionality of the
  # Karma module.
  def help(m)
    p = self.class.prefix.call(m)
    m.reply("See: #{p}help karma")
  end

  private

  def increment(element)
    element.downcase!
    if element =~ /\((.+)\)\+\+/
      key = $1
    elsif element =~ /(\S+)\+\+/
      key = $1
    else
      return
    end

    karma_value = @@karma_db[key] ? @@karma_db[key] : 0
    if karma_value == -1
      @@karma_db.delete(key)
    else
      @@karma_db[key] = karma_value + 1
    end
  end

  def decrement(element)
    element.downcase!
    if element =~ /\((.+)\)--/
      key = $1
    elsif element =~ /(\S+)--/
      key = $1
    else
      return
    end

    karma_value = @@karma_db[key] ? @@karma_db[key] : 0
    if karma_value == 1
      @@karma_db.delete(key)
    else
      @@karma_db[key] = karma_value - 1
    end
  end

  def init_db
    return unless @@karma_db.nil?
    @@karma_db = KeyValueDatabase::SQLite.new('karma.sqlite3') do |config|
      config.table = 'karma'
      config.key_type = String
      config.value_type = Integer
    end
  end
end
