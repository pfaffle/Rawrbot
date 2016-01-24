Rawrbot - An IRC Bot
====================
![Build status](https://travis-ci.org/pfaffle/Rawrbot.svg?branch=master)

Rawrbot is an IRC bot written in Ruby which uses the Cinch framework (https://github.com/cinchrb/cinch).

Functionality comes from plugins loaded into the bot. Plugins can be written using Ruby and the Cinch API.

The original purpose of Rawrbot was to be a tool to assist Portland State University's Office of Information Technology Help Desk technicians. Many of the plugins I've written are specifically geared towards IT support and are only useful for that purpose. Other plugins are more generic or are simply for-fun.

Requirements:
-------------

Rawrbot itself requires
* Ruby v1.9.x, and
* The 'Cinch' Ruby gem.

Individual plugins have their own requirements, which are listed at the top of the plugin file.

Quick Start Guide:
------------------

* Install RVM (https://rvm.io/)

* Clone the Rawrbot Git repo.

    `git clone https://github.com/pfaffle/Rawrbot.git`

* Change directories to the location where you cloned the bot.

    `cd Rawrbot`

* Install a compatible Ruby

    `rvm install 1.9.3`

* Install Bundler

    `gem install bundler`

* Use Bundler to install the required gems.

    `bundle install`

* Copy sample config files from the config/samples directory into the config/ directory, then edit them as desired.

    `cp config/samples/config.yml config/config.yml`
    
    `vim config/config.yml`

Samples are provided for the main Rawrbot config file and for each of the plugins. You *must* provide a general Rawrbot config file (config/config.yml). Other config files are only required if you intend to use the corresponding plugin.

* Run the bot within screen or tmux.

    `./rawrbot.rb`

Contributing to Rawrbot:
------------------------

Contributions are welcome! If you want to contribute to Rawrbot, please fork it and submit a pull request with your changes.

To create a new plugin, simply create a file with a name ending in .rb in the plugins/ directory which contains a Class that includes Cinch::Plugin. Use other plugins as examples to work from when creating a new plugin.

Add your plugin's Class name to the comma-separated list of plugins in config/config.yml if you want it to be automatically loaded when the bot starts.

For more details, consult the Cinch documentation (http://www.rubydoc.info/github/cinchrb/cinch/) and see more examples at Cinch's Github.com repo (https://github.com/cinchrb/cinch).
