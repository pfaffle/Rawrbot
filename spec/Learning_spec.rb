require 'plugins/Learning'
require 'database_helper'

def get_replies_to(message)
  get_replies(make_message(@bot, message, channel: channel))
end

RSpec::Matchers.define :be_an_acknowledgement do
  # When using cinch-test, the nick of the user sending the message is
  # always 'test' and can't be overridden.
  usr = 'test'
  match do |actual|
    ["good to know, #{usr}.", "got it, #{usr}.", "roger, #{usr}.",
     "understood, #{usr}.", "OK, #{usr}.", "so speaketh #{usr}.",
     "whatever you say, #{usr}.", "I'll take your word for it, #{usr}."]
        .include?(actual.text)
  end
end

RSpec::Matchers.define :give_up do
  # When using cinch-test, the nick of the user sending the message is
  # always 'test' and can't be overridden.
  usr = 'test'
  match do |actual|
    ["bugger all, I dunno, #{usr}.", "no idea, #{usr}.", "huh?", "what?",
     "dunno, #{usr}."]
        .include?(actual.text)
  end
end

describe 'Learning' do
  let(:db_file) { 'learning.sqlite3' }
  let(:table) { 'learning' }
  let(:bot_nick) { 'testbot' }

  before(:each) do
    @bot = new_bot_with_plugins(Learning)
    @bot.set_nick(bot_nick)
    @bot.config.prefix = '!'
    @db = KeyValueDatabase::SQLite.new(db_file) do |config|
      config.table = table
    end
    #@bot.plugins[0].use_db(@db)
  end
  after(:each) do
    @db.close
    #File.delete(db_file)
  end

  context 'bot does not know of item' do
    let(:key) { 'foo' }
    let(:value) { 'bar' }
    let(:channel) { '#testchan' }

    before(:each) do
      delete_key_from_db(@db, key)
    end

    it 'should admit it' do
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first).to give_up
      expect(@db[key]).to be(nil)
    end

    it 'should literally admit it' do
      replies = get_replies_to("#{bot_nick}: literal #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("No entry for #{key}")
      expect(@db[key]).to be(nil)
    end

    it 'should not be able to forget it' do
      replies = get_replies_to("#{bot_nick}: forget #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("I don't know anything about #{key}.")
      expect(@db[key]).to be(nil)
    end

    it 'should not be able to edit it' do
      replies = get_replies_to("#{bot_nick}: #{key} =~ s/foo/bar/")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("I don't know anything about #{key}.")
      expect(@db[key]).to be(nil)
    end

    it 'should learn' do
      replies = get_replies_to("#{bot_nick}: #{key} is #{value}")
      expect(replies.length).to eq 1
      expect(replies.first).to be_an_acknowledgement
      expect(@db[key]).to eq(value)
    end

    it 'should learn using a lowercase key' do
      replies = get_replies_to("#{bot_nick}: #{key.upcase} is #{value}")
      expect(replies.length).to eq 1
      expect(replies.first).to be_an_acknowledgement
      expect(@db[key.upcase]).to be(nil)
      expect(@db[key.downcase]).to eq(value)
    end
  end
end
