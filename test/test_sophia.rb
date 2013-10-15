require 'rubygems'
require 'bundler/setup'
Bundler.require :default, :test
require 'minitest/spec'
require 'minitest/autorun'
require 'sophia'
require 'tmpdir'
require 'fileutils'

describe Sophia do
  before { @tmpdir = Dir.mktmpdir }
  after  { FileUtils.remove_entry_secure @tmpdir }

  it 'open' do
    Sophia.open(@tmpdir).must_be_instance_of Sophia
  end

  it 'open with block' do
    retval = rand
    Sophia.open(@tmpdir) { |sophia| retval }.must_equal retval
  end

  it 'get/set' do
    sophia = Sophia.new @tmpdir
    sophia['key'] = 'value'

    sophia['key'].must_equal 'value'
  end

  it 'fetch' do
    sophia = Sophia.new @tmpdir
    sophia['key'] = 'value'

    sophia.fetch('key').must_equal 'value'
  end

  it 'fetch not exists key' do
    sophia = Sophia.new @tmpdir

    sophia.fetch('key').must_be_nil
  end

  it 'fetch with default value' do
    sophia = Sophia.new @tmpdir

    sophia.fetch('key', '123').must_equal '123'
  end

  it 'fetch with block' do
    sophia = Sophia.new @tmpdir

    sophia.fetch('key') { |key|
      key.must_equal 'key'
      '456'
    }.must_equal '456'
  end

  it 'delete' do
    sophia = Sophia.new @tmpdir
    sophia['key'] = 'val'

    sophia.delete('key').must_equal 'val'
  end

  it 'delete not exists key' do
    sophia = Sophia.new @tmpdir

    sophia.delete('key').must_be_nil
  end
end
