require 'plugins/Learning'
require 'database_helper'

# NOTE: When using cinch-test, the nick of the user sending the message is
# always 'test' and can't be overridden.

def get_replies_to(message)
  get_replies(make_message(@bot, message, channel: channel))
end

RSpec::Matchers.define :be_an_acknowledgement do
  match do |actual|
    ['good to know, test.', 'got it, test.', 'roger, test.',
     'understood, test.', 'OK, test.', 'so speaketh test.',
     'whatever you say, test.', "I'll take your word for it, test."]
      .include?(actual.text)
  end
end

RSpec::Matchers.define :be_a_successful_edit do
  match do |actual|
    'done, test.' == actual.text
  end
end

RSpec::Matchers.define :give_up do
  match do |actual|
    ['bugger all, I dunno, test.', 'no idea, test.', 'huh?', 'what?',
     'dunno, test.']
      .include?(actual.text)
  end
end

describe 'Learning' do
  let(:db_file) {'test_learning.sqlite3'}
  let(:table) {'learning'}
  let(:bot_nick) {'testbot'}

  before(:each) do
    @bot = new_bot_with_plugins(Learning)
    @bot.set_nick(bot_nick)
    @bot.config.prefix = '!'
    @db = KeyValueDatabase::SQLite.new(db_file) do |config|
      config.table = table
    end
    @bot.plugins[0].use_db(@db)
  end
  after(:each) do
    @db.close
    File.delete(db_file)
  end

  context 'bot does not know of entry' do
    let(:key) {'foo'}
    let(:value) {'bar'}
    let(:channel) {'#testchan'}

    before(:each) do
      delete_key_from_db(@db, key)
    end

    it 'should admit it' do
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first).to give_up
    end

    it 'should literally admit it' do
      replies = get_replies_to("#{bot_nick}: literal #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("No entry for #{key}")
    end

    it 'should not be able to forget it' do
      replies = get_replies_to("#{bot_nick}: forget #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("I don't know anything about #{key}.")
    end

    it 'should not be able to edit it' do
      replies = get_replies_to("#{bot_nick}: #{key} =~ s/foo/bar/")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("I don't know anything about #{key}.")
    end

    it 'should learn in a case-insensitive way' do
      replies = get_replies_to("#{bot_nick}: #{key} is #{value}")
      expect(replies.length).to eq 1
      expect(replies.first).to be_an_acknowledgement
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("#{key} is #{value}.")
    end
  end

  context 'bot knows of an entry without special keywords' do
    let(:key) {'foo'}
    let(:value) {'bar'}
    let(:channel) {'#testchan'}

    before(:each) do
      set_db_key_value(@db, key, value)
    end

    it 'should teach it' do
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("#{key} is #{value}.")
    end

    it 'should literally teach it' do
      replies = get_replies_to("#{bot_nick}: literal #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("#{key} =is= #{value}.")
    end

    it 'should be able to forget it' do
      replies = get_replies_to("#{bot_nick}: forget #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("I forgot #{key}.")
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first).to give_up
    end

    it 'should be able to edit it' do
      replies = get_replies_to("#{bot_nick}: #{key} =~ s/#{value}/baz/")
      expect(replies.length).to eq 1
      expect(replies.first).to be_a_successful_edit
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("#{key} is baz.")
    end

    it 'should be able to add to it' do
      replies = get_replies_to("#{bot_nick}: #{key} is baz")
      expect(replies.length).to eq 1
      expect(replies.first).to be_an_acknowledgement
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("#{key} is #{value} or baz.")
    end
  end

  context 'bot knows of an entry with the <reply> keyword' do
    let(:key) {'foo'}
    let(:value) {'<reply>bar'}
    let(:channel) {'#testchan'}

    before(:each) do
      set_db_key_value(@db, key, value)
    end

    it 'should teach it' do
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq(value.gsub('<reply>', ''))
    end

    it 'should literally teach it' do
      replies = get_replies_to("#{bot_nick}: literal #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("#{key} =is= #{value}.")
    end

    it 'should be able to forget it' do
      replies = get_replies_to("#{bot_nick}: forget #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("I forgot #{key}.")
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first).to give_up
    end

    it 'should be able to edit it' do
      replies = get_replies_to(
        "#{bot_nick}: #{key} =~ s/#{Regexp.escape(value)}/baz/")
      expect(replies.length).to eq 1
      expect(replies.first).to be_a_successful_edit
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("#{key} is baz.")
    end

    it 'should be able to add to it' do
      replies = get_replies_to("#{bot_nick}: #{key} is baz")
      expect(replies.length).to eq 1
      expect(replies.first).to be_an_acknowledgement
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text)
        .to eq("#{value.gsub('<reply>', '')} or baz")
    end
  end

  context 'bot knows of an entry with the $who keyword' do
    let(:key) {'foo'}
    let(:value) {'$who bar'}
    let(:channel) {'#testchan'}

    before(:each) do
      set_db_key_value(@db, key, value)
    end

    it 'should teach it' do
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text)
        .to eq("#{key} is #{value.gsub('$who','test')}.")
    end

    it 'should literally teach it' do
      replies = get_replies_to("#{bot_nick}: literal #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text)
        .to eq("#{key} =is= #{value}.")
    end

    it 'should be able to forget it' do
      replies = get_replies_to("#{bot_nick}: forget #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("I forgot #{key}.")
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first).to give_up
    end

    it 'should be able to edit it' do
      replies = get_replies_to(
        "#{bot_nick}: #{key} =~ s/#{Regexp.escape(value)}/baz/")
      expect(replies.length).to eq 1
      expect(replies.first).to be_a_successful_edit
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("#{key} is baz.")
    end

    it 'should be able to add to it' do
      replies = get_replies_to("#{bot_nick}: #{key} is baz")
      expect(replies.length).to eq 1
      expect(replies.first).to be_an_acknowledgement
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text)
        .to eq("#{key} is #{value.gsub('$who', 'test')} or baz.")
    end
  end

  # TODO: add some tests around | special case
end
