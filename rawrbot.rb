#!/usr/bin/env ruby
# (c) Craig Meinschein 2011
# Licensed under the GPLv3 or any later version.
# File:			rawrbot.rb
# Description:
# 	rawrbot. An irc bot implemented in Ruby, using the Cinch framework from:
#	 	http://www.rubyinside.com/cinch-a-ruby-irc-bot-building-framework-3223.html
#		A work in progress.


$pwd = Dir.pwd
require 'cinch'
Dir["#{$pwd}/plugins/*plugin*.rb"].each do |file| 
	require file
	puts "Loading #{file}."
end

# =============================================================================
# Plugin: Messenger
#
# Description:
# 	Sends a PM to a user.
#
# Requirements:
# 	none
class Messenger
	include Cinch::Plugin
	
	match(/tell (.+?) (.+)/)
	
	# Function: execute
	#
	# Description:
	# 	Tells someone something.
	def execute(m, receiver, message)
		m.reply "Done."
		User(receiver).send(message)
	end
end
# End of plugin: Messenger
# =============================================================================


# Launch the bot.
require "#{$pwd}/config.rb"
config_hash = ret_config

bot = Cinch::Bot.new do
	configure do |config|
		config.server		= config_hash['server']
		config.port			= config_hash['port']
		config.channels	= config_hash['channels']
		config.ssl.use	= config_hash['ssl']
		config.nick			= config_hash['nick']
		config.realname	= config_hash['realname']
		config.user			= config_hash['user']
		config.plugins.plugins = [LDAPsearch,Social,Messenger,Karma,Learning,RTSearch,SendSignal,GoogleRSS]
	end

	# Authenticate with NickServ.
	on :connect do |m|
		if (config_hash.has_key? 'nickpass')
			if (bot.nick != config_hash['nick'])
				User('NickServ').send "regain #{config_hash['nick']} #{config_hash['nickpass']}"
			end
			User('NickServ').send "identify #{config_hash['nick']} #{config_hash['nickpass']}"
		end
	end
end

# Make CTRL+C shut down the bot cleanly.
Kernel.trap('INT') { bot.quit(config_hash['quitmsg']) }

bot.start
