# Dynamically unload and load plugins, including this one!
class Reload
    include Cinch::Plugin

    set :prefix, lambda { |m| m.bot.config.plugins.prefix }

    match /unload (\w+)/, :method => :unload_plugin
    match /load (\w+)/, :method => :load_plugin
    match /reload (\w+)/, :method => :reload_plugin

    # Check if plugin filename exists, return it.
    def get_plugin_file(pname)
        plugindir = Dir.new("#{$pwd}/plugins")
        pname += '.rb' if !pname.end_with? '.rb'
        plugindir.each do |filename|
            if pname.casecmp(filename.downcase).zero?
                return "#{plugindir.path}/#{filename}"
            end
        end
        return nil
    end
    
    # Find plugin amongst loaded plugins, return the class object.
    def get_plugin_class(m, pname)
        m.bot.plugins.each do |plugin|
            if pname.casecmp(plugin.class.plugin_name.downcase).zero?
                return plugin
            end
        end
        return nil
    end

    def unload_plugin(m, pname, announce = true)
        plugin = get_plugin_class(m,pname)
        if plugin
            m.bot.plugins.unregister_plugin(plugin)
            m.reply "Plugin unloaded." if announce
            return true
        end
        m.reply "Plugin is not loaded."
        return false
    end
    
    def load_plugin(m, pname, announce = true)
        filename = get_plugin_file(pname)
        if filename
            pname = File.basename(filename,'.rb')
            load filename
            m.bot.plugins.register_plugin(Object.const_get(pname))
            m.reply "Plugin loaded." if announce
            return true
        end
        m.reply "Plugin not found."
        return false
    end
    
    def reload_plugin(m, pname)
        if (unload_plugin(m,pname,false) && load_plugin(m,pname,false))
            m.reply "Plugin reloaded."
        end
    end
end

