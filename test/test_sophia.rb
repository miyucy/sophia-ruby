require 'rubygems'
require 'bundler/setup'
Bundler.require
require 'minitest/spec'
require 'minitest/autorun'
require 'sophia'
require 'tmpdir'

describe Sophia do
  it 'get/set' do
    path = Dir.mktmpdir
    sophia = Sophia.new path
    sophia['key'] = 'value'
    sophia['key'].must_equal 'value'
  end

  it 'fetch' do
    path = Dir.mktmpdir
    sophia = Sophia.new path

    sophia.fetch('key', '123').must_equal '123'
  end

  it 'fetch block' do
    path = Dir.mktmpdir
    sophia = Sophia.new path

    sophia.fetch('key') { |key|
      key.must_equal 'key'
      '456'
    }.must_equal '456'
  end
end
