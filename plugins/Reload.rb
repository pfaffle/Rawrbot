# Dynamically unload and load plugins, including this one!
class Reload
  include Cinch::Plugin

  set(:prefix, ->(m) { m.bot.config.plugins.prefix })

  match(/unload (\w+)/, method: :unload_plugin)
  match(/load (\w+)/, method: :load_plugin)
  match(/reload (\w+)/, method: :reload_plugin)

  # Check if plugin filename exists, return it.
  def get_plugin_file(pname)
    plugindir = Dir.new("#{$pwd}/plugins")
    pname += '.rb' unless pname.end_with? '.rb'
    plugindir.each do |filename|
      return "#{plugindir.path}/#{filename}" if pname.casecmp(filename).zero?
    end
  end

  # Find plugin amongst loaded plugins, return the class object.
  def get_plugin_class(m, pname)
    m.bot.plugins.each do |plugin|
      return plugin if pname.casecmp(plugin.class.plugin_name).zero?
    end
  end

  def unload_plugin(m, pname, announce = true)
    plugin = get_plugin_class(m, pname)
    if plugin
      m.bot.plugins.unregister_plugin(plugin)
      m.reply 'Plugin unloaded.' if announce
      return true
    end
    m.reply 'Plugin is not loaded.'
  end

  def load_plugin(m, pname, announce = true)
    filename = get_plugin_file(pname)
    if filename
      pname = File.basename(filename, '.rb')
      load filename
      m.bot.plugins.register_plugin(Object.const_get(pname))
      m.reply 'Plugin loaded.' if announce
      return true
    end
    m.reply 'Plugin not found.'
  end

  def reload_plugin(m, pname)
    m.reply 'Plugin reloaded.' if unload_plugin(m, pname, false) && load_plugin(m, pname, false)
  end
end
