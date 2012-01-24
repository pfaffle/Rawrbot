#!/usr/bin/env ruby
# Import Karma
#
# Import karma information from a flat file into a GDBM database.
# This script will replace any duplicate key information in the
# GDBM database with information from the flat file. In other words,
# it assumes the flat file is authoritative.
# Takes two command-line arguments.
#
# The first argument is the path to a flat file which contains 
# the karma information to import into the database. The file
# should be formatted as a series of key-value pairs, separated
# by a delimiter. Only one key-value pair should exist per line.
# For example:
#
# foo => 30
# bar => -1
#
#	The delimiter can be edited here:
#
delimiter = ' => '
#
# The second argument is the path to the GDBM database file to which
# you would like to import karma information. Be sure rawrbot is not
# running and using that database when you begin importing data.

require 'gdbm'

source_text = ARGV[0]
target_db = ARGV[1]

# Check if input and output files exist. Prompt to create output file
# if it is missing.
if !(File.exists? source_text)
	abort "File #{source_text} not found. Aborting.\n"
elsif !(File.exists? target_db)
	print "File #{target_db} not found. Create new database? "
	create_db = STDIN.gets
	if create_db =~ /ye?s?/i
		# continue
	elsif create_db =~ /no?/i
		abort "Aborting.\n"
	else
		abort "Unrecognized input. Aborting.\n"
	end
end

# Import data into database.
File.open(source_text, 'r') do |file|
	GDBM.open(target_db) do |db|
		while (line = file.gets)
			line =~ /(.+)#{delimiter}(.+)/i 
			db["#{$1}"] = "#{$2}"
		end
	end
end
