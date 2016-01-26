class KeyValueDatabase
  # A wrapper class around another database provider to act as a
  # simple key-value store.
  class SQLite
    require 'sqlite3'

    def initialize(filename)
      @db = SQLite3::Database.new(filename)
      @db.execute('CREATE TABLE IF NOT EXISTS data(key TEXT PRIMARY KEY, val TEXT)')
    end

    def close
      @db.close
    end

    def []=(key, value)
      set(key, value)
    end

    def set(key, val)
      @db.transaction do |txn|
        if get(key).nil?
          txn.execute('INSERT INTO data (key,val) VALUES (?,?)', key, val)
        else
          txn.execute('UPDATE data SET val=? WHERE key=?', val, key)
        end
      end
    end

    def [](key)
      get(key)
    end

    def get(key)
      @db.get_first_value('SELECT val FROM data WHERE key=?', key)
    end
  end
end
