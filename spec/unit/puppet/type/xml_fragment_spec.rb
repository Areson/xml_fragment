require 'spec_helper'

describe Puppet::Type.type(:xml_fragment) do
  describe 'when validating property values' do
    describe 'content' do
      it 'accepts hashes' do
        expect { described_class.new(:name => 'example_resource', :content => {}) }.to_not raise_error
      end
      it 'rejects strings' do
        expect { described_class.new(:name => 'example_resource', :content => 'invalid') }.to raise_error(Puppet::Error, %r{`content` must be a hash})
      end
      describe 'value key' do
        it 'accepts strings' do
          expect { described_class.new(:name => 'example_resource', :content => { 'value' => 'some value' }) }.to_not raise_error
        end
        it 'rejects non strings' do
          expect { described_class.new(:name => 'example_resource', :content => { 'value' => 1 }) }.to raise_error(Puppet::Error, %r{content\['value'\]` must be a string if specified})
        end
      end
      describe 'attributes key' do
        it 'accepts a non empty hash' do
          expect { described_class.new(:name => 'example_resource', :content => { 'attributes' => {'foo' => 'bar' }}) }.to_not raise_error
        end
        it 'does not support empty hashes' do
          expect { described_class.new(:name => 'example_resource', :content => { 'attributes' => {} }) }.to raise_error(Puppet::Error, %r{You must specify at least one attribute for a tag if you include the attributes hash})
        end
        it 'does not accept strings' do
          expect { described_class.new(:name => 'example_resource', :content => { 'attributes' => 'invalid' }) }.to raise_error(Puppet::Error, %r{attributes must be a hash})
        end
      end
    end
  end
end
