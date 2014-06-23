#!/usr/bin/env ruby
# ==============================================================================
# Export GDBM
# ==============================================================================
#
# This script exports information to a flat file from a GDBM database. It takes
# two command-line arguments.
#
# export_gdbm.rb [source db] [target file]
#
# The first argument is the path to a GDBM database which contains the
# information to export to the flat-file. The second argument is the path to the
# output flat-file. Be sure that the bot is not running and using that database
# when you begin exporting data.
#
# The output file is formatted as a series of key-value pairs, separated by a
# delimiter. Only one key-value pair exists per line. For example:
#
# foo => 30
# bar => -1
#
# The delimiter can be edited here:
delimiter = ' => '
#

require 'gdbm'

source = ARGV[0]
target = ARGV[1]

# Check if input file exists.
if !(File.exists?(source))
  abort("File #{source} not found. Aborting.\n")
end

# Export data to output file.
puts("Exporting...")
GDBM.open(source) do |db|
  File.open(target, 'w:ASCII') do |file|
    db.each_pair() do |key,val|
      begin
        key.delete!("\r")
        key.delete!("\n")
        val.delete!("\r")
        val.delete!("\n")
        file.write("#{key}#{delimiter}#{val}\n")
      rescue => e
        warn("Failed to parse line. Error: #{e}\nLine: #{key}#{delimiter}#{val}")
      end
    end
  end
end
puts("Done.")
