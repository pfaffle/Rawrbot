#!/usr/bin/env ruby
# Import Learning
#
# Import learned factoids from a flat file into a GDBM database.
# This script will non-destructively append data from the flat
# file to the database, if the key already exists.
# Takes two command-line arguments.
#
# The first argument is the path to a flat file which contains 
# the information to import into the database. The file
# should be formatted as a series of key-value pairs, separated
# by a delimiter. Only one key-value pair should exist per line.
# For example:
#
# foo => a silly person
# bar => a solid object or a difficult test or a place to beer
#
#    The delimiter can be edited here:
#
delimiter = ' => '
#
# The second argument is the path to the GDBM database file to which
# you would like to import information. Be sure rawrbot is not
# running and using that database when you begin importing data.

source_text = ARGV[0]
target_db = ARGV[1]

require 'gdbm'

# Check if the input and output files exist. Prompt user to
# create output file if it is missing.
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
            if db.has_key? "#{$1}"
                db["#{$1}"] = "#{db["#{$1}"]} or #{$2}"
            else
                db["#{$1}"] = "#{$2}"
            end
        end
    end
end
