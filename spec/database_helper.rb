require 'rspec'
require 'lib/key_value_db'

def delete_key_from_db(db, key)
  db.delete(key)
  expect(db.get(key)).to eq nil
end

def set_db_key_value(db, key, val)
  delete_key_from_db(db, key)
  db.set(key, val)
  expect(db.get(key)).to eq val
end
