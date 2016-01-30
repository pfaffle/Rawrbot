require 'lib/key_value_db'

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
  before(:each) do
    @db = KeyValueDatabase::SQLite.new(db_name)
  end
  after(:each) do
    @db.close
    File.delete(db_name)
  end

  it 'exists' do
    expect(File).to exist("./#{db_name}")
  end

  context 'with get and set methods' do
    it 'returns nothing for a nonexistent key' do
      expect(@db.get('foo')).to be(nil)
    end

    it 'gets the existing value if key is set' do
      insert_into_db('foo', 'bar')
      expect(@db.get('foo')).to eq('bar')
    end

    it 'inserts a new key' do
      @db.set('foo', 'bar')
      expect(get_from_db('foo')).to eq('bar')
    end

    it 'updates an existing key' do
      insert_into_db('foo', 'bar')
      @db.set('foo', 'baz')
      expect(get_from_db('foo')).to eq('baz')
    end

    it 'deletes an existing key' do
      insert_into_db('foo', 'bar')
      @db.delete('foo')
      expect(get_from_db('foo')).to be(nil)
    end
  end

  context 'with hash-style syntax' do
    it 'returns nothing for a nonexistent key' do
      expect(@db['foo']).to be(nil)
    end

    it 'gets the existing value if key is set' do
      insert_into_db('foo', 'bar')
      expect(@db['foo']).to eq('bar')
    end

    it 'inserts a new key' do
      @db['foo'] = 'bar'
      expect(get_from_db('foo')).to eq('bar')
    end

    it 'updates an existing key' do
      insert_into_db('foo', 'bar')
      @db['foo'] = 'baz'
      expect(get_from_db('foo')).to eq('baz')
    end
  end
end
