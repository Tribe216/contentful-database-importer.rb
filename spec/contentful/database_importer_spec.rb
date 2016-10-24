require 'spec_helper'

class FileDouble
  def write(*); end
  def close; end
  def unlink; end
  def path; 'foo'; end
end

describe Contentful::DatabaseImporter do
  it 'has a version number' do
    expect(Contentful::DatabaseImporter::VERSION).not_to be nil
  end

  describe 'class methods' do
    before :each do
      described_class.config.space_name = nil
      described_class.config.database_connection = nil
    end

    describe '::config' do
      it 'returns a default config when empty' do
        expect(described_class.config).to be_a Contentful::DatabaseImporter::Config
        expect(described_class.config.complete?).to be_falsey
      end

      it 'returns the settuped config when modified' do
        described_class.config.database_connection = 'foo'
        described_class.config.space_name = 'bar'

        expect(described_class.config.complete?).to be_truthy
      end
    end

    describe '::setup' do
      it 'yields a config for setup' do
        described_class.setup do |config|
          expect(config).to be_a Contentful::DatabaseImporter::Config
          config.space_name = 'foo'
          config.database_connection = 'bar'
        end

        expect(described_class.config.complete?).to be_truthy
      end

      it 'fails if configuration is not complete after setup' do
        expect {
          described_class.setup do |config|
          end
        }.to raise_error 'Configuration is incomplete'
      end
    end

    describe '::database' do
      it 'returns a database object' do
        expect(::Sequel).to receive(:connect) { DatabaseDouble.new }

        described_class.setup do |config|
          config.space_name = 'foo'
          config.database_connection = 'bar'
        end

        described_class.database
      end

      it 'fails if database configuration is not found' do
        expect { described_class.database }.to raise_error 'Database Configuration not found'
      end
    end

    describe '::generate_json' do
      it 'calls the JSON Generator' do
        expect(Contentful::DatabaseImporter::JsonGenerator).to receive(:generate_json)
        described_class.generate_json
      end
    end

    describe '::generate_json!' do
      it 'calls the JSON Generator' do
        expect(Contentful::DatabaseImporter::JsonGenerator).to receive(:generate_json!)
        described_class.generate_json!
      end
    end

    describe '::run!' do
      it 'calls bootstrap with the json in a tempfile' do
        file = FileDouble.new
        expect(Contentful::DatabaseImporter::JsonGenerator).to receive(:generate_json!)
        expect(Tempfile).to receive(:new) { file }
        expect_any_instance_of(Contentful::Bootstrap::CommandRunner).to receive(:create_space).with('foo', json_template: 'foo')

        described_class.setup do |config|
          config.space_name = 'foo'
          config.database_connection = 'bar'
        end

        described_class.run!
      end
    end
  end
end
