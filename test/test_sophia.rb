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

  it 'length' do
    sophia = Sophia.new @tmpdir

    sophia.length.must_equal 0
  end

  it 'length with key' do
    sophia = Sophia.new @tmpdir
    sophia['key'] = 'val'

    sophia.length.must_equal 1
  end

  it 'empty?' do
    sophia = Sophia.new @tmpdir

    sophia.must_be :empty?
  end

  it 'empty? with key' do
    sophia = Sophia.new @tmpdir
    sophia['key'] = 'val'

    sophia.wont_be :empty?
  end

  it 'access to closed sophia db' do
    sophia = Sophia.new @tmpdir
    sophia.close

    lambda { sophia['key'] = 'val' }.must_raise SophiaError
  end

  it 'each' do
    sophia = Sophia.new @tmpdir
    sophia['key1'] = 'val1'
    sophia['key2'] = 'val2'
    keys, vals = [], []
    sophia.each { |k, v| keys << k; vals << v }

    keys.must_equal %w[key1 key2]
    vals.must_equal %w[val1 val2]
  end

  it 'each_key' do
    sophia = Sophia.new @tmpdir
    sophia['key1'] = 'val1'
    sophia['key2'] = 'val2'
    keys = []
    sophia.each_key { |k| keys << k }

    keys.must_equal %w[key1 key2]
  end

  it 'each_value' do
    sophia = Sophia.new @tmpdir
    sophia['key1'] = 'val1'
    sophia['key2'] = 'val2'
    vals = []
    sophia.each_value { |v| vals << v }

    vals.must_equal %w[val1 val2]
  end

  it 'find' do
    sophia = Sophia.new @tmpdir
    sophia['key1'] = 'val1'
    sophia['key2'] = 'val2'
    sophia['key3'] = 'val3'
    sophia['key4'] = 'val4'
    expect = %w[key2 val2]

    sophia.find { |key, val|
      [key, val] == expect
    }.must_equal expect
  end

  it 'key' do
    sophia = Sophia.new @tmpdir
    sophia['key1'] = 'val1'

    sophia.key('val1').must_equal 'key1'
  end

  it 'key with not exists key' do
    sophia = Sophia.new @tmpdir

    sophia.key('val1').must_be_nil
  end

  it 'values_at' do
    sophia = Sophia.new @tmpdir
    sophia['key1'] = 'val1'
    sophia['key2'] = 'val2'
    sophia['key3'] = 'val3'

    sophia.values_at('key1', 'key3').must_equal %w[val1 val3]
  end

  it 'values_at with not exists key' do
    sophia = Sophia.new @tmpdir
    sophia['key1'] = 'val1'

    sophia.values_at('key4', 'key1').must_equal [nil, 'val1']
  end

  it 'values_at with no args' do
    sophia = Sophia.new @tmpdir

    sophia.values_at.must_be :empty?
  end
end
