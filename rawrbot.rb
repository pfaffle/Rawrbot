#!/usr/bin/env ruby
# (c) Craig Meinschein 2016
# Licensed under the GPLv3 or any later version.
# An irc bot implemented in Ruby, using the Cinch framework from:
# https://github.com/cinchrb/cinch
require 'cinch'
require 'yaml'
require_relative './lib/config_loader'

$pwd = Dir.pwd
$LOAD_PATH.unshift(File.dirname(__FILE__))

config_hash = ConfigLoader.new("#{$pwd}/config").load

plugins = []
config_hash['Config']['plugins'].each do |plugin|
  file = "#{$pwd}/plugins/#{plugin}.rb"
  load file
  plugins.push(Object.const_get(plugin))
  puts "Loading #{file}."
end
bot_config = config_hash['Config']

bot = Cinch::Bot.new do
  configure do |config|
    config.server = bot_config['server']
    config.port = bot_config['port']
    config.channels = bot_config['channels']
    config.ssl.use = bot_config['ssl']
    config.nick = bot_config['nick']
    config.realname = bot_config['realname']
    config.user = bot_config['user']
    config.plugins.plugins = plugins
    config.plugins.prefix = /^#{bot_config['prefix']}/
    config.plugins.options = config_hash
  end

  # Authenticate with NickServ.
  # This is specifically designed for Charybdis IRCD.
  on :connect do
    if bot_config.key?('nickpass')
      if bot.nick != bot_config['nick']
        User('NickServ').send "regain #{bot_config['nick']} #{bot_config['nickpass']}"
      end
      User('NickServ').send "identify #{bot_config['nick']} #{bot_config['nickpass']}"
    end
  end
end

# Make CTRL+C shut down the bot cleanly.
quit_thread = nil
Kernel.trap('INT') do
  quit_thread = Thread.new { bot.quit(bot_config['quitmsg']) }
end

# Launch the bot.
bot.start
quit_thread.join
