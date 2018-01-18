class KeyValueDatabase
  # A wrapper class around another database provider to act as a
  # simple key-value store.
  class SQLite
    require 'sqlite3'

    attr_accessor :table, :key_type, :value_type

    def initialize(filename)
      @db = SQLite3::Database.new(filename)
      @table = 'data'
      @key_type = String
      @value_type = String
      yield self if block_given?
      init_db
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
          txn.execute("INSERT INTO #{@table} (key,val) VALUES (?,?)", key, val)
        else
          txn.execute("UPDATE #{@table} SET val=? WHERE key=?", val, key)
        end
      end
    end

    def [](key)
      get(key)
    end

    def get(key)
      @db.get_first_value("SELECT val FROM #{@table} WHERE key=?", key)
    end

    def delete(key)
      @db.transaction do |txn|
        txn.execute("DELETE FROM #{@table} WHERE key=?", key)
      end
    end

    private

    def init_db
      @db.execute("CREATE TABLE IF NOT EXISTS #{@table}("\
                      "key #{to_sql_type(@key_type)} PRIMARY KEY, "\
                      "val #{to_sql_type(@value_type)})")
    end

    def to_sql_type(type)
      map = {
        String => 'TEXT',
        Integer => 'INT'
      }
      raise("Unsupported type #{type}") if map[type].nil?
      map[type]
    end
  end
end
