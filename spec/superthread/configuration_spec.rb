# frozen_string_literal: true

require 'tmpdir'

RSpec.describe Superthread::Configuration do
  subject(:config) { described_class.new }

  describe '#initialize' do
    it 'sets default base_url' do
      expect(config.base_url).to eq('https://api.superthread.com/v1')
    end

    it 'sets default format to json' do
      expect(config.format).to eq('json')
    end
  end

  describe '#api_key' do
    context 'when SUPERTHREAD_API_KEY env var is set' do
      around do |example|
        original = ENV['SUPERTHREAD_API_KEY']
        ENV['SUPERTHREAD_API_KEY'] = 'test_key_from_env'
        example.run
        ENV['SUPERTHREAD_API_KEY'] = original
      end

      it 'uses the env var value' do
        expect(config.api_key).to eq('test_key_from_env')
      end
    end
  end

  describe '#workspace' do
    context 'when SUPERTHREAD_WORKSPACE_ID env var is set' do
      around do |example|
        original = ENV['SUPERTHREAD_WORKSPACE_ID']
        ENV['SUPERTHREAD_WORKSPACE_ID'] = 'ws_from_env'
        example.run
        ENV['SUPERTHREAD_WORKSPACE_ID'] = original
      end

      it 'uses the env var value' do
        expect(config.workspace).to eq('ws_from_env')
      end
    end
  end

  describe '#base_url' do
    context 'when SUPERTHREAD_API_BASE_URL env var is set' do
      around do |example|
        original = ENV['SUPERTHREAD_API_BASE_URL']
        ENV['SUPERTHREAD_API_BASE_URL'] = 'https://custom.api.com'
        example.run
        ENV['SUPERTHREAD_API_BASE_URL'] = original
      end

      it 'uses the env var value' do
        expect(config.base_url).to eq('https://custom.api.com')
      end
    end
  end

  describe '#config_path' do
    it 'returns XDG-compliant path' do
      expect(config.config_path).to end_with('superthread/config.yaml')
    end

    context 'when XDG_CONFIG_HOME is set' do
      around do |example|
        original = ENV['XDG_CONFIG_HOME']
        ENV['XDG_CONFIG_HOME'] = '/custom/config'
        example.run
        ENV['XDG_CONFIG_HOME'] = original
      end

      it 'uses XDG_CONFIG_HOME' do
        expect(config.config_path).to eq('/custom/config/superthread/config.yaml')
      end
    end
  end

  describe '#save_workspace' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:config_path) { File.join(temp_dir, 'superthread', 'config.yaml') }

    around do |example|
      original = ENV['XDG_CONFIG_HOME']
      ENV['XDG_CONFIG_HOME'] = temp_dir
      example.run
      ENV['XDG_CONFIG_HOME'] = original
      FileUtils.rm_rf(temp_dir)
    end

    it 'creates config directory and file' do
      config.save_workspace('ws_test123')
      expect(File.exist?(config_path)).to be true
    end

    it 'saves workspace to config file' do
      config.save_workspace('ws_test123')
      saved_config = YAML.safe_load_file(config_path)
      expect(saved_config['workspace']).to eq('ws_test123')
    end

    it 'updates instance workspace' do
      config.save_workspace('ws_test123')
      expect(config.workspace).to eq('ws_test123')
    end

    it 'preserves existing config values' do
      FileUtils.mkdir_p(File.dirname(config_path))
      File.write(config_path, YAML.dump({ 'api_key' => 'existing_key', 'format' => 'table' }))

      config.save_workspace('ws_new')

      saved_config = YAML.safe_load_file(config_path)
      expect(saved_config['api_key']).to eq('existing_key')
      expect(saved_config['format']).to eq('table')
      expect(saved_config['workspace']).to eq('ws_new')
    end
  end
end
