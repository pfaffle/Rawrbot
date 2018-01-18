#!/usr/bin/env ruby
# (c) Craig Meinschein 2016
# Licensed under the GPLv3 or any later version.
# An irc bot implemented in Ruby, using the Cinch framework from:
# https://github.com/cinchrb/cinch
require 'cinch'
require 'yaml'

config_hash = YAML.safe_load(File.read('config/config.yml'))
$pwd = Dir.pwd
$LOAD_PATH.unshift(File.dirname(__FILE__))
$admins = config_hash['admins']

plugins = []
config_hash['plugins'].each do |plugin|
  file = "#{$pwd}/plugins/#{plugin}.rb"
  load file
  plugins.push(Object.const_get(plugin))
  puts "Loading #{file}."
end

bot = Cinch::Bot.new do
  configure do |config|
    config.server = config_hash['server']
    config.port = config_hash['port']
    config.channels = config_hash['channels']
    config.ssl.use = config_hash['ssl']
    config.nick = config_hash['nick']
    config.realname = config_hash['realname']
    config.user = config_hash['user']
    config.plugins.plugins = plugins
    config.plugins.prefix = /^#{config_hash['prefix']}/
  end

  # Authenticate with NickServ.
  # This is specifically designed for Charybdis IRCD.
  on :connect do
    if config_hash.key?('nickpass')
      if (bot.nick != config_hash['nick'])
        User('NickServ').send "regain #{config_hash['nick']} #{config_hash['nickpass']}"
      end
      User('NickServ').send "identify #{config_hash['nick']} #{config_hash['nickpass']}"
    end
  end
end

# Make CTRL+C shut down the bot cleanly.
quit_thread = nil
Kernel.trap('INT') do
  quit_thread = Thread.new { bot.quit(config_hash['quitmsg']) }
end

# Launch the bot.
bot.start
quit_thread.join
