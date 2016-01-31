require 'rspec'

RSpec.shared_examples 'a key-value store that contains' do |key_value_hash|
  let(:key) { key_value_hash.keys[0].to_s }
  let(:value) { key_value_hash[key] }

  context 'with get and set methods' do
    it 'returns nothing for a nonexistent key' do
      expect(@db.get(key)).to be(nil)
    end

    it 'gets the existing value if key is set' do
      insert_into_db(key, value)
      expect(@db.get(key)).to eq(value)
    end

    it 'inserts a new key' do
      @db.set(key, value)
      expect(get_from_db(key)).to eq(value)
    end

    it 'updates an existing key' do
      insert_into_db(key, 'some existing value')
      @db.set(key, value)
      expect(get_from_db(key)).to eq(value)
    end

    it 'deletes an existing key' do
      insert_into_db(key, 'some existing value')
      @db.delete(key)
      expect(get_from_db(key)).to be(nil)
    end
  end

  context 'with hash-style syntax' do
    it 'returns nothing for a nonexistent key' do
      expect(@db[key]).to be(nil)
    end

    it 'gets the existing value if key is set' do
      insert_into_db(key, value)
      expect(@db[key]).to eq(value)
    end

    it 'inserts a new key' do
      @db[key] = value
      expect(get_from_db(key)).to eq(value)
    end

    it 'updates an existing key' do
      insert_into_db(key, 'some existing value')
      @db[key] = value
      expect(get_from_db(key)).to eq(value)
    end
  end
end
