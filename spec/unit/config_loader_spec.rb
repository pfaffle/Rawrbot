require 'rspec'
require 'yaml'
require_relative '../../lib/config_loader'

# Create a yaml configuration file using a hash passed in via a block
def create_yaml_file(path)
  File.open(path, 'w:UTF-8') do |stream|
    stream.write(YAML.dump(yield))
  end
end

describe 'ConfigLoader' do
  before(:each) do
    @dir = Dir.mktmpdir
  end
  after(:each) do
    FileUtils.rm_rf(@dir)
  end

  it 'should throw if it encounters a non-yaml file' do
    File.open("#{@dir}/test.yml", 'w:UTF-8') do |stream|
      stream.puts("{{#!garbage\n")
    end
    expect {ConfigLoader.new(@dir).load}.to raise_error(Psych::SyntaxError)
  end

  it 'should load a yaml file with a single word class name' do
    config = {
      'key' => 'value',
      'key2' => 'value2'
    }
    create_yaml_file("#{@dir}/test.yml") {config}
    expect(ConfigLoader.new(@dir).load).to eq('Test' => config)
  end

  it 'should load a yaml file with a multi-word class name' do
    config = {
      'key' => 'value',
      'key2' => 'value2'
    }
    create_yaml_file("#{@dir}/plugin_name.yml") {config}
    expect(ConfigLoader.new(@dir).load).to eq('PluginName' => config)
  end

  it 'should load multiple yaml files' do
    config1 = {
      'key' => 'value',
      'key2' => 'value2'
    }
    config2 = {
      'otherkey' => 'othervalue'
    }
    create_yaml_file("#{@dir}/plugin_name.yml") {config1}
    create_yaml_file("#{@dir}/test.yml") {config2}
    expect(ConfigLoader.new(@dir).load).to eq('PluginName' => config1, 'Test' => config2)
  end
end
