require 'plugins/Karma'

def delete_key_from_db(key)
  @db.delete(key)
  expect(@db.get(key)).to eq nil
end

def set_db_key_value(key, val)
  delete_key_from_db(key)
  @db.set(key, val)
  expect(@db.get(key)).to eq val
end

RSpec.describe 'Karma' do
  let(:db_file) { 'test_karma.sqlite3' }
  let(:table) { 'karma' }

  before(:each) do
    @bot = make_bot
    @bot.loggers.level = :error
    @bot.plugins.register_plugin(Karma)
    @db = KeyValueDatabase::SQLite.new(db_file) do |config|
      config.key_type = String
      config.value_type = Integer
      config.table = table
    end
    @bot.plugins[0].use_db(@db)
  end
  after(:each) do
    @db.close
    File.delete(db_file)
  end

  context 'key does not have a karma value' do
    context 'with a single-word key' do
      let(:karma_key) { 'imatestkey' }
      before(:each) do
        delete_key_from_db(karma_key)
      end

      it 'shows karma as neutral' do
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has neutral karma."
      end
      it 'shows karma as 1 after incrementing' do
        msg = make_message(@bot, "#{karma_key}++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of 1."
      end
      it 'shows karma as 2 after incrementing twice on one line' do
        msg = make_message(@bot, "#{karma_key}++ #{karma_key}++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of 2."
      end
      it 'shows karma as -1 after decrementing' do
        msg = make_message(@bot, "#{karma_key}--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of -1."
      end
      it 'shows karma as -2 after decrementing twice on one line' do
        msg = make_message(@bot, "#{karma_key}-- #{karma_key}--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of -2."
      end
    end

    context 'with a multi-word key' do
      let(:karma_key) { 'multi word key' }
      before(:each) do
        delete_key_from_db(karma_key)
      end

      it 'shows karma as neutral' do
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has neutral karma."
      end
      it 'shows karma as 1 after incrementing' do
        msg = make_message(@bot, "(#{karma_key})++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of 1."
      end
      it 'shows karma as 2 after incrementing twice on one line' do
        msg = make_message(@bot, "(#{karma_key})++ (#{karma_key})++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of 2."
      end
      it 'shows karma as -1 after decrementing' do
        msg = make_message(@bot, "(#{karma_key})--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of -1."
      end
      it 'shows karma as -2 after decrementing twice on one line' do
        msg = make_message(@bot, "(#{karma_key})-- (#{karma_key})--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of -2."
      end
    end
  end

  context 'key has an existing karma value of -1' do
    let(:karma_value) { -1 }

    context 'with a single-word key' do
      let(:karma_key) { 'imatestkey' }

      before(:each) do
        set_db_key_value(karma_key, karma_value)
      end

      it 'shows existing karma value' do
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value}."
      end
      it 'shows karma as neutral after incrementing' do
        msg = make_message(@bot, "#{karma_key}++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has neutral karma."
      end
      it 'shows karma as 1 after incrementing twice in one line' do
        msg = make_message(@bot, "#{karma_key}++ #{karma_key}++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of 1."
      end
      it 'shows karma as 1 fewer after decrementing' do
        msg = make_message(@bot, "#{karma_key}--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value - 1}."
      end
      it 'shows karma as 2 fewer after decrementing twice in one line' do
        msg = make_message(@bot, "#{karma_key}-- #{karma_key}--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value - 2}."
      end
    end

    context 'with a multi-word key' do
      let(:karma_key) { 'multi word key' }

      before(:each) do
        set_db_key_value(karma_key, karma_value)
      end

      it 'shows existing karma value' do
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value}."
      end
      it 'shows karma as neutral after incrementing' do
        msg = make_message(@bot, "(#{karma_key})++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has neutral karma."
      end
      it 'shows karma as 1 after incrementing twice in one line' do
        msg = make_message(@bot, "(#{karma_key})++ (#{karma_key})++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of 1."
      end
      it 'shows karma as 1 fewer after decrementing' do
        msg = make_message(@bot, "(#{karma_key})--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value - 1}."
      end
      it 'shows karma as 2 fewer after decrementing twice in one line' do
        msg = make_message(@bot, "(#{karma_key})-- (#{karma_key})--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value - 2}."
      end
    end
  end

  context 'key has an existing karma value of 1' do
    let(:karma_value) { 1 }

    context 'with a single-word key' do
      let(:karma_key) { 'imatestkey' }

      before(:each) do
        set_db_key_value(karma_key, karma_value)
      end

      it 'shows existing karma value' do
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value}."
      end
      it 'shows karma as 1 more after incrementing' do
        msg = make_message(@bot, "#{karma_key}++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value + 1}."
      end
      it 'shows karma as 2 more after incrementing twice in one line' do
        msg = make_message(@bot, "#{karma_key}++ #{karma_key}++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value + 2}."
      end
      it 'shows karma as neutral after decrementing' do
        msg = make_message(@bot, "#{karma_key}--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has neutral karma."
      end
      it 'shows karma as -1 after decrementing twice in one line' do
        msg = make_message(@bot, "#{karma_key}-- #{karma_key}--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of -1."
      end
    end

    context 'with a multi-word key' do
      let(:karma_key) { 'multi word key' }

      before(:each) do
        set_db_key_value(karma_key, karma_value)
      end

      it 'shows existing karma value' do
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value}."
      end
      it 'shows karma as 1 more after incrementing' do
        msg = make_message(@bot, "(#{karma_key})++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value + 1}."
      end
      it 'shows karma as 2 more after incrementing twice in one line' do
        msg = make_message(@bot, "(#{karma_key})++ (#{karma_key})++", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value + 2}."
      end
      it 'shows karma as neutral after decrementing' do
        msg = make_message(@bot, "(#{karma_key})--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has neutral karma."
      end
      it 'shows karma as -1 after decrementing twice in one line' do
        msg = make_message(@bot, "(#{karma_key})-- (#{karma_key})--", channel: '#testchan')
        expect(get_replies(msg).length).to eq 0
        msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
        expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of -1."
      end
    end
  end

  context 'key has an existing karma value that is not 1 or -1' do
    [-9999, -4, 32, 10601].each do |val|
      let(:karma_value) { val }

      context 'with a single-word key' do
        let(:karma_key) { 'imatestkey' }

        before(:each) do
          set_db_key_value(karma_key, karma_value)
        end

        it 'shows existing karma value' do
          msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
          expect(get_replies(msg).length).to eq 1
          expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value}."
        end
        it 'shows karma as 1 more after incrementing' do
          msg = make_message(@bot, "#{karma_key}++", channel: '#testchan')
          expect(get_replies(msg).length).to eq 0
          msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
          expect(get_replies(msg).length).to eq 1
          expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value + 1}."
        end
        it 'shows karma as 2 more after incrementing twice in one line' do
          msg = make_message(@bot, "#{karma_key}++ #{karma_key}++", channel: '#testchan')
          expect(get_replies(msg).length).to eq 0
          msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
          expect(get_replies(msg).length).to eq 1
          expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value + 2}."
        end
        it 'shows karma as 1 fewer after decrementing' do
          msg = make_message(@bot, "#{karma_key}--", channel: '#testchan')
          expect(get_replies(msg).length).to eq 0
          msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
          expect(get_replies(msg).length).to eq 1
          expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value - 1}."
        end
        it 'shows karma as 2 fewer after decrementing twice in one line' do
          msg = make_message(@bot, "#{karma_key}-- #{karma_key}--", channel: '#testchan')
          expect(get_replies(msg).length).to eq 0
          msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
          expect(get_replies(msg).length).to eq 1
          expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value - 2}."
        end
      end

      context 'with a multi-word key' do
        let(:karma_key) { 'multi word key' }

        before(:each) do
          set_db_key_value(karma_key, karma_value)
        end

        it 'shows existing karma value' do
          msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
          expect(get_replies(msg).length).to eq 1
          expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value}."
        end
        it 'shows karma as 1 more after incrementing' do
          msg = make_message(@bot, "(#{karma_key})++", channel: '#testchan')
          expect(get_replies(msg).length).to eq 0
          msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
          expect(get_replies(msg).length).to eq 1
          expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value + 1}."
        end
        it 'shows karma as 2 more after incrementing twice in one line' do
          msg = make_message(@bot, "(#{karma_key})++ (#{karma_key})++", channel: '#testchan')
          expect(get_replies(msg).length).to eq 0
          msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
          expect(get_replies(msg).length).to eq 1
          expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value + 2}."
        end
        it 'shows karma as 1 fewer after decrementing' do
          msg = make_message(@bot, "(#{karma_key})--", channel: '#testchan')
          expect(get_replies(msg).length).to eq 0
          msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
          expect(get_replies(msg).length).to eq 1
          expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value - 1}."
        end
        it 'shows karma as 2 fewer after decrementing twice in one line' do
          msg = make_message(@bot, "(#{karma_key})-- (#{karma_key})--", channel: '#testchan')
          expect(get_replies(msg).length).to eq 0
          msg = make_message(@bot, "!karma #{karma_key}", channel: '#testchan')
          expect(get_replies(msg).length).to eq 1
          expect(get_replies(msg)[0].text).to eq "#{karma_key} has karma of #{karma_value - 2}."
        end
      end
    end
  end
end
