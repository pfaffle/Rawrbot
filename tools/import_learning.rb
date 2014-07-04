#!/usr/bin/env ruby
# ==============================================================================
# Import Learning
# ==============================================================================
#
# Import learned factoids from a flat file into a sqlite database. This script
# will non-destructively append data from the flat file to the database, if the
# key already exists. Takes one command-line argument.
#
# The command-line argument is the path to the flat file which contains the
# information to import into the database. The file should be formatted as a
# series of key-value pairs, separated by a delimiter. Only one key-value pair
# should exist per line. For example:
#
# foo => a silly person
# bar => a solid object or a difficult test or a place to beer
#
# The delimiter can be edited here:
#
delimiter = ' => '

require 'sqlite3'

source = ARGV[0]
target = 'learning.sqlite3'

# Check if input file exists.
if !(File.exists?(source))
  abort("Source file #{source} not found. Aborting.\n")
end

# Initialize database.
db = SQLite3::Database.new(target)
db.execute("CREATE TABLE IF NOT EXISTS learning(
              key TEXT PRIMARY KEY,
              val TEXT)")

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
    r = db.get_first_value("SELECT val FROM learning WHERE key=?", key)
    begin
      next if (val == '')
      if (r.nil?)
        # Element does not yet exist in the db; insert it.
        db.execute("INSERT INTO learning (key,val) VALUES (?,?)", key, val)
      else
        # Element already exists in the db; update it.
        db.execute("UPDATE learning SET val=? WHERE key=?",
                   "#{r} or #{val}",
                   key)
      end
    rescue => e
      warn("Failed to insert data. Error: #{e}\nLine: #{line}")
      next
    end
  end
end
puts("Done.")
