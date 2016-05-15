# Tracks positive and negative karma for a given item. Increments karma when
# someone adds a ++ after a word (or a series of words encapsulated by
# parentheses) and decrements karma when someone adds -- to the same.
#
# Requirements:
# - The Ruby gem 'sqlite3' must be installed.
#
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
      increment(strip_parens(strip_operator(element.downcase)))
    end
  end

  # Decrements karma by one point for each element that has a -- after it. If
  # an element reaches neutral (0) karma, it is deleted from the DB so the DB
  # doesn't grow any larger than it has to.
  def decrement_all(m)
    m.message.scan(/\([^)]+\)--|\S+--/).each do |element|
      decrement(strip_parens(strip_operator(element.downcase)))
    end
  end

  # Displays the current karma level of the requested element. If the element
  # does not exist in the DB, it has neutral (0) karma.
  def display_karma(m, element)
    karma_value = @@karma_db[element.downcase.strip]
    if karma_value.nil?
      m.reply("#{element.strip} has neutral karma.")
    else
      m.reply("#{element.strip} has karma of #{karma_value}.")
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
    karma_value = @@karma_db[element] ? @@karma_db[element] : 0
    if karma_value == -1
      @@karma_db.delete(element)
    else
      @@karma_db[element] = karma_value + 1
    end
  end

  def decrement(element)
    karma_value = @@karma_db[element] ? @@karma_db[element] : 0
    if karma_value == 1
      @@karma_db.delete(element)
    else
      @@karma_db[element] = karma_value - 1
    end
  end

  def strip_operator(element)
    if element.end_with?('++')
      return element.chomp('++')
    elsif element.end_with?('--')
      return element.chomp('--')
    end
    element
  end

  def strip_parens(element)
    if element.start_with?('(') && element.end_with?(')')
      return element[1, element.length - 2]
    end
    element
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
