require 'yaml'

# Loads a set of yaml config files into a hash of hashes
# The keys of the hash are the file names converted into Ruby class names
# For example, a file lamed twitter_plugin.rb will be loaded into the key
# 'TwitterPlugin'.
class ConfigLoader
  attr_reader :config_dir

  def initialize(config_dir)
    @config_dir = config_dir
  end

  def load
    config = {}
    Dir.glob("#{@config_dir}/*.yml").each do |file_name|
      config[to_class_name(file_name)] = YAML.safe_load(File.read(file_name))
    end
    config
  end

  def to_class_name(file_name)
    base_name = File.basename(file_name).split('.').first
    base_name.capitalize.gsub(/_([a-z])/) { |match| match.delete('_').capitalize }
  end
end
