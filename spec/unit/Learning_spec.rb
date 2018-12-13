require 'plugins/Learning'
require 'database_helper'

# NOTE: When using cinch-test, the nick of the user sending the message is
# always 'test' and can't be overridden.

def get_replies_to(message)
  get_replies(make_message(@bot, message, channel: channel))
end

def max_message_length(bot_nick)
  # this logic is copied, only partially modified from cinch source code, where it
  # determines how to split messages in target#send
  maxlength = 510 - (":" + " PRIVMSG " + " :").size
  maxlength - bot_nick.length
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
    actual.text == 'done, test.'
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
  let(:db_file) { 'test_learning.sqlite3' }
  let(:table) { 'learning' }
  let(:bot_nick) { 'testbot' }
  let(:prefix) { /^!/ }
  before(:each) do
    @bot = new_bot_with_plugins(Learning)
    @bot.set_nick(bot_nick)
    @bot.config.plugins.prefix = prefix
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

    it 'should be able to learn an entry with the configured prefix in it' do
      replies = get_replies_to("#{bot_nick}: #{key} is #{prefix}#{value}")
      expect(replies.length).to eq 1
      expect(replies.first).to be_an_acknowledgement
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text).to eq("#{key} is #{prefix}#{value}.")
    end
  end

  context 'bot knows of an entry without special keywords' do
    let(:key) { 'foo' }
    let(:value) { 'bar' }
    let(:channel) { '#testchan' }

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
    let(:key) { 'foo' }
    let(:value) { '<reply>bar' }
    let(:channel) { '#testchan' }

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
        "#{bot_nick}: #{key} =~ s/#{Regexp.escape(value)}/baz/"
      )
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
    let(:key) { 'foo' }
    let(:value) { '$who bar' }
    let(:channel) { '#testchan' }

    before(:each) do
      set_db_key_value(@db, key, value)
    end

    it 'should teach it' do
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.length).to eq 1
      expect(replies.first.text)
        .to eq("#{key} is #{value.gsub('$who', 'test')}.")
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
        "#{bot_nick}: #{key} =~ s/#{Regexp.escape(value)}/baz/"
      )
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

  context 'bot has an entry which is very long' do
    # cinch splits long messages in the underlying 'send' method, not in 'reply', so we have to actually
    # check the length of the string rather than the number of messages sent
    let(:key) { 'foo' }
    let(:value) { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ullamcorper velit sed ullamcorper morbi tincidunt ornare massa eget egestas. Fermentum posuere urna nec tincidunt praesent semper feugiat nibh sed. Quam nulla porttitor massa id neque aliquam vestibulum morbi blandit. Dui faucibus in ornare quam. Id porta nibh venenatis cras sed felis. Consequat nisl vel pretium lectus. Faucibus interdum posuere lorem ipsum dolor sit amet. Eget felis eget nunc lobortis mattis aliquam faucibus purus in. Risus feugiat in ante metus dictum at tempor. Eget aliquet nibh praesent tristique magna sit amet. Aliquam vestibulum morbi blandit cursus. Porta non pulvinar neque laoreet suspendisse interdum consectetur. Diam donec adipiscing tristique risus nec. Viverra vitae congue eu consequat ac felis donec et. Sagittis aliquam malesuada bibendum arcu vitae elementum. Amet purus gravida quis blandit turpis cursus in. Enim sit amet venenatis urna cursus eget nunc. Vel orci porta non pulvinar. Sapien et ligula ullamcorper malesuada proin libero nunc consequat. Id diam maecenas ultricies mi eget mauris pharetra et. Nam at lectus urna duis convallis. Viverra maecenas accumsan lacus vel facilisis volutpat est velit egestas. Placerat orci nulla pellentesque dignissim enim. Bibendum arcu vitae elementum curabitur. Duis ultricies lacus sed turpis tincidunt. Fermentum iaculis eu non diam phasellus vestibulum lorem sed. Montes nascetur ridiculus mus mauris. Commodo nulla facilisi nullam vehicula ipsum a. Quam quisque id diam vel quam. Magna ac placerat vestibulum lectus mauris ultrices eros. Vestibulum morbi blandit cursus risus at ultrices. Morbi tristique senectus et netus et. Praesent elementum facilisis leo vel fringilla. Id aliquet risus feugiat in ante metus dictum at. Vestibulum mattis ullamcorper velit sed ullamcorper morbi. Mattis pellentesque id nibh tortor id. Velit scelerisque in dictum non consectetur. Elementum nibh tellus molestie nunc non blandit. Arcu non sodales neque sodales ut etiam. Iaculis nunc sed augue lacus viverra vitae congue eu. Suscipit adipiscing bibendum est ultricies. Proin sed libero enim sed faucibus. Ullamcorper sit amet risus nullam eget felis eget nunc lobortis. Nunc aliquet bibendum enim facilisis gravida neque convallis a cras. Dis parturient montes nascetur ridiculus mus. Fermentum et sollicitudin ac orci phasellus egestas tellus. Mattis rhoncus urna neque viverra justo nec. Nibh ipsum consequat nisl vel pretium lectus quam id. Eget sit amet tellus cras adipiscing enim eu turpis egestas' }
    let(:value_with_action) { "<action>#{value}" }
    let(:channel) { '#testchan' }

    before(:each) do
      set_db_key_value(@db, key, value)
    end

    it 'should cut off its response' do
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.first.text.size).to be < max_message_length(bot_nick)
      expect(replies.first.text)
        .to start_with("#{key} is").and include("#{value[0,20]}").and end_with('...')
    end

    it 'should cut off its response even if it is an action' do
      replies = get_replies_to("#{bot_nick}: #{key}")
      expect(replies.first.text.size).to be < max_message_length(bot_nick)
      expect(replies.first.text)
        .to start_with("#{key} is").and include("#{value[0,20]}").and end_with('...')
    end
  end
  # TODO: add some tests around | special case
end
