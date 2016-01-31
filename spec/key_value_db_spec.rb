require 'lib/key_value_db'
require 'shared_examples/key_value_db'

def insert_into_db(key, value)
  db = SQLite3::Database.new(db_name)
  db.execute('INSERT INTO data (key,val) VALUES (?,?)', key, value)
  db.close
  expect(get_from_db(key)).to eq(value)
end

def get_from_db(key)
  db = SQLite3::Database.new(db_name)
  result = db.get_first_value('SELECT val FROM data WHERE key=?', key)
  db.close
  result
end

RSpec.describe 'KeyValueDatabase::SQLite' do
  let(:db_name) { 'testdb.sqlite3' }

  after(:each) do
    @db.close
    File.delete(db_name)
  end

  context 'with the default String=>String key-value store' do
    before(:each) do
      @db = KeyValueDatabase::SQLite.new(db_name)
    end
    it 'exists' do
      expect(File).to exist("./#{db_name}")
    end
    it_behaves_like 'a key-value store that contains', 'foo' => 'bar'
  end

  context 'with a String=>Integer key-value store' do
    before(:each) do
      @db = KeyValueDatabase::SQLite.new(db_name, String, Integer)
    end
    it 'exists' do
      expect(File).to exist("./#{db_name}")
    end
    it_behaves_like 'a key-value store that contains', 'foo' => 4
  end
end
