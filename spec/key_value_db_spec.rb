require 'lib/key_value_db'
require 'shared_examples/key_value_db'

def insert_into_db(key, value)
  db = SQLite3::Database.new(db_file)
  db.execute("INSERT INTO #{table_name} (key,val) VALUES (?,?)", key, value)
  db.close
  expect(get_from_db(key)).to eq(value)
end

def get_from_db(key)
  db = SQLite3::Database.new(db_file)
  result = db.get_first_value("SELECT val FROM #{table_name} WHERE key=?", key)
  db.close
  result
end

RSpec.describe 'KeyValueDatabase::SQLite' do
  let(:db_file) { 'testdb.sqlite3' }
  let(:table_name) { 'data' } # the default

  after(:each) do
    @db.close
    File.delete(db_file)
  end

  context 'with the default String=>String key-value store' do
    before(:each) do
      @db = KeyValueDatabase::SQLite.new(db_file)
    end

    it 'exists' do
      expect(File).to exist("./#{db_file}")
    end

    it_behaves_like 'a key-value store that contains', 'foo' => 'bar'
  end

  context 'with a String=>Integer key-value store' do
    let(:key_type) { String }
    let(:value_type) { Integer }

    before(:each) do
      @db = KeyValueDatabase::SQLite.new(db_file) do |db|
        db.key_type = key_type
        db.value_type = value_type
      end
    end

    it 'exists' do
      expect(File).to exist("./#{db_file}")
    end

    it_behaves_like 'a key-value store that contains', 'foo' => 4
  end

  context 'with a custom table name' do
    let(:table_name) { 'custom_table' }

    before(:each) do
      @db = KeyValueDatabase::SQLite.new(db_file) do |db|
        db.table = table_name
      end
    end

    it 'exists' do
      expect(File).to exist("./#{db_file}")
    end

    it_behaves_like 'a key-value store that contains', 'foo' => 'bar'
  end
end
