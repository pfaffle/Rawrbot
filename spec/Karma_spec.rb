require 'plugins/Karma'

def delete_key_from_db(db, key)
  db.execute('DELETE FROM karma WHERE key=?', key)
  expect(db.get_first_value('SELECT val FROM karma WHERE key=?', key)).to eq nil
end

def set_db_key_value(db, key, val)
  delete_key_from_db(db, key)
  db.execute('INSERT INTO karma (key,val) VALUES (?,?)', key, val)
  expect(db.get_first_value('SELECT val FROM karma WHERE key=?', key)).to eq val
end

def get_random_number_list()
  list = []
  max_num = 1000
  rng = Random.new()
  3.times do
    list << rng.rand(max_num)
    list << -rng.rand(max_num)
  end
  return list.shuffle
end

RSpec.describe 'Karma#display' do
  before(:each) do
    @bot = make_bot()
    @bot.loggers.level = :error
    @bot.plugins.register_plugin(Karma)
  end

  context 'key does not exist in the database' do
    let(:key) { 'imatestvalue' }
    let(:db) { 'karma.sqlite3' }

    before(:each) do
      # TODO: refactor Karma plugin so we can use a test-only db here
      delete_key_from_db(SQLite3::Database.new(db), key)
    end

    it 'replies once' do
      msg = make_message(@bot, "!karma #{key}", channel: '#testchan')
      expect(get_replies(msg).length).to eq 1
    end
    it 'shows karma as neutral' do
      msg = make_message(@bot, "!karma #{key}", channel: '#testchan')
      expect(get_replies(msg)[0].text).to eq "#{key} has neutral karma."
    end
  end

  context 'key has a value in the database' do
    let(:key) { 'imatestvalue' }
    let(:db) { 'karma.sqlite3' }

    get_random_number_list().each do |val|
      let(:karma_value) { val }

      before(:each) do
        # TODO: refactor Karma plugin so we can use a test-only db here
        set_db_key_value(SQLite3::Database.new(db), key, karma_value)
      end

      it 'replies once' do
        msg = make_message(@bot, "!karma #{key}", channel: '#testchan')
        expect(get_replies(msg).length).to eq 1
      end
      it 'shows existing karma value' do
        msg = make_message(@bot, "!karma #{key}", channel: '#testchan')
        expect(get_replies(msg)[0].text).to eq "#{key} has karma of #{karma_value}."
      end
    end
  end
end
