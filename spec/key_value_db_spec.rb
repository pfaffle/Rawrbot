require 'lib/key_value_db'

RSpec.describe 'KeyValueDatabase' do
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

    it 'inserts a new key' do
      @db.set('foo', 'bar')
      expect(@db.get('foo')).to eq('bar')
    end

    it 'updates an existing key' do
      @db.set('foo', 'bar')
      @db.set('foo', 'baz')
      expect(@db.get('foo')).to eq('baz')
    end
  end

  context 'with hash-style syntax' do
    it 'returns nothing for a nonexistent key' do
      expect(@db['foo']).to be(nil)
    end

    it 'inserts a new key' do
      @db['foo'] = 'bar'
      expect(@db['foo']).to eq('bar')
    end

    it 'updates an existing key' do
      @db['foo'] = 'bar'
      @db['foo'] = 'baz'
      expect(@db['foo']).to eq('baz')
    end
  end
end
