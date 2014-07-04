#!/usr/bin/env ruby
# ==============================================================================
# Import Karma
# ==============================================================================
#
# Import karma information from a flat file into a sqlite3 database. This script
# will replace any duplicate key information in the database with information
# from the flat file. In other words, it assumes the flat file is authoritative.
# Takes one command-line argument.
#
# The command-line argument is the path to the flat file which contains the
# karma information to import into the database. The file should be formatted as
# a series of key-value pairs, separated by a delimiter. Only one key-value pair
# should exist per line. For example:
#
# foo => 30
# bar => -1
#
# The delimiter can be edited here:
#
delimiter = ' => '

require 'sqlite3'

source = ARGV[0]
target = 'karma.sqlite3'

# Check if input file exists.
if !(File.exists?(source))
  abort("Source file #{source} not found. Aborting.\n")
end

# Initialize database.
db = SQLite3::Database.new(target)
db.execute("CREATE TABLE IF NOT EXISTS karma(
              key TEXT PRIMARY KEY,
              val INTEGER)")

# Import data into database.
puts("Importing...")
File.open(source, 'r:UTF-8') do |file|
  while (line = file.gets)
    begin
      line.delete!("\r")
      line.delete!("\n")
      line =~ /(.+)#{delimiter}(.+)/i 
    rescue => e
      warn("Failed to parse line. Error: #{e}\nLine: #{line}")
      next
    end
    key = $1
    val = $2
    r = db.get_first_value("SELECT val FROM karma WHERE key=?", key)
    begin
      next if (val == '0')
      if (r.nil?)
        # Element does not yet exist in the db; insert it.
        db.execute("INSERT INTO karma (key,val) VALUES (?,?)", key, val)
      else
        # Element already exists in the db; update it.
        db.execute("UPDATE karma SET val=? WHERE key=?", val, key)
      end
    rescue => e
      warn("Failed to insert data. Error: #{e}\nLine: #{line}")
      next
    end
  end
end
puts("Done.")
