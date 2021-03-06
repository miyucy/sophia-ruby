require 'rubygems'
require 'bundler/setup'
Bundler.require :default, :test
require 'minitest/spec'
require 'minitest/autorun'
require 'sophia'
require 'tmpdir'
require 'fileutils'

describe Sophia, 'open' do
  before { @tmpdir = Dir.mktmpdir }
  after  { FileUtils.remove_entry_secure @tmpdir }

  it 'open' do
    Sophia.open(@tmpdir).must_be_instance_of Sophia
  end

  it 'open with block' do
    retval = rand
    Sophia.open(@tmpdir) { |sophia| retval }.must_equal retval
  end

  it 'should be closed' do
    sophia = nil
    Sophia.open(@tmpdir) { |_sophia| sophia = _sophia }
    sophia.closed?.must_equal true
  end

  it 'raise error' do
    lambda { Sophia.open }.must_raise ArgumentError
  end
end

describe Sophia do
  before do
    @tmpdir = Dir.mktmpdir
    @sophia = Sophia.new @tmpdir
  end

  after  do
    @sophia.close unless @sophia.closed?
    FileUtils.remove_entry_secure @tmpdir
  end

  it 'raise error' do
    lambda { Sophia.new }.must_raise ArgumentError
  end

  it 'get/set' do
    @sophia['key'] = 'value'

    @sophia['key'].must_equal 'value'
  end

  it 'fetch' do
    @sophia['key'] = 'value'

    @sophia.fetch('key').must_equal 'value'
  end

  it 'fetch not exists key' do
    @sophia.fetch('key').must_be_nil
  end

  it 'fetch with default value' do
    @sophia.fetch('key', '123').must_equal '123'
  end

  it 'fetch with block' do
    @sophia.fetch('key') { |key|
      key.must_equal 'key'
      '456'
    }.must_equal '456'
  end

  it 'delete' do
    @sophia['key'] = 'val'

    @sophia.delete('key').must_equal 'val'
  end

  it 'delete not exists key' do
    @sophia.delete('key').must_be_nil
  end

  it 'length' do
    @sophia.length.must_equal 0
  end

  it 'length with key' do
    @sophia['key'] = 'val'

    @sophia.length.must_equal 1
  end

  it 'empty?' do
    @sophia.must_be_empty
  end

  it 'empty? with key' do
    @sophia['key'] = 'val'

    @sophia.wont_be_empty
  end

  it 'access to closed @sophia db' do
    @sophia.close

    lambda { @sophia['key'] = 'val' }.must_raise SophiaError
  end

  it 'each' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    keys, vals = [], []
    @sophia.each { |k, v| keys << k; vals << v }

    keys.must_equal %w[key1 key2]
    vals.must_equal %w[val1 val2]
  end

  it 'each_key' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    keys = []
    @sophia.each_key { |k| keys << k }

    keys.must_equal %w[key1 key2]
  end

  it 'each_value' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    vals = []
    @sophia.each_value { |v| vals << v }

    vals.must_equal %w[val1 val2]
  end

  it 'find' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    @sophia['key4'] = 'val4'
    expect = %w[key2 val2]

    @sophia.find { |key, val|
      [key, val] == expect
    }.must_equal expect
  end

  it 'key' do
    @sophia['key1'] = 'val1'

    @sophia.key('val1').must_equal 'key1'
  end

  it 'key with not exists key' do
    @sophia.key('val1').must_be_nil
  end

  it 'values_at' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'

    @sophia.values_at('key1', 'key3').must_equal %w[val1 val3]
  end

  it 'values_at with not exists key' do
    @sophia['key1'] = 'val1'

    @sophia.values_at('key4', 'key1').must_equal [nil, 'val1']
  end

  it 'values_at with no args' do
    @sophia.values_at.must_be_empty
  end

  it 'keys' do
    @sophia['key'] = 'val'

    @sophia.keys.must_equal ['key']
  end

  it 'keys with empty db' do
    @sophia.keys.must_be_empty
  end

  it 'values' do
    @sophia['key'] = 'val'

    @sophia.values.must_equal ['val']
  end

  it 'values with empty db' do
    @sophia.values.must_be_empty
  end

  it 'clear' do
    @sophia['key'] = 'val'
    @sophia.clear

    @sophia.must_be_empty
  end

  it 'clear return nil' do
    @sophia.clear.must_be_nil
  end

  it 'update' do
    @sophia.update('key' => 'val')

    @sophia['key'].must_equal 'val'
  end

  it 'update with empty hash' do
    @sophia.update({})

    @sophia.must_be_empty
  end

  it 'replace' do
    @sophia.update('key1' => 'val1', 'key2' => 'val2')
    @sophia.replace('key3' => 'val3')

    @sophia.size.must_equal 1
    @sophia['key3'].must_equal 'val3'
  end

  it 'has_key?' do
    @sophia['key'] = 'val'

    @sophia.must_include 'key'
  end

  it 'has_key? with not exists key' do
    @sophia.wont_include 'key'
  end

  it 'has_value?' do
    @sophia['key'] = 'val'

    @sophia.has_value?('val').must_equal true
  end

  it 'has_value? with empty db' do
    @sophia.has_value?('val').must_equal false
  end

  it 'each SPGT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    keys = []
    @sophia.each(Sophia::SPGT) { |k, v| keys << k }

    keys.must_equal %w[key1 key2 key3]
  end

  it 'each SPLT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    keys = []
    @sophia.each(Sophia::SPLT) { |k, v| keys << k }

    keys.must_equal %w[key1 key2 key3].reverse
  end

  it 'each enumerator SPGT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    enum = @sophia.each(Sophia::SPGT)

    enum.next.must_equal %w[key1 val1]
    enum.next.must_equal %w[key2 val2]
    enum.next.must_equal %w[key3 val3]
  end

  it 'each enumerator SPLT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    enum = @sophia.each(Sophia::SPLT)

    enum.next.must_equal %w[key3 val3]
    enum.next.must_equal %w[key2 val2]
    enum.next.must_equal %w[key1 val1]
  end

  it 'each_key SPGT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    keys = []
    @sophia.each_key(Sophia::SPGT) { |k| keys << k }

    keys.must_equal %w[key1 key2 key3]
  end

  it 'each_key SPLT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    keys = []
    @sophia.each_key(Sophia::SPLT) { |k| keys << k }

    keys.must_equal %w[key1 key2 key3].reverse
  end

  it 'each_key enumerator SPGT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    enum = @sophia.each_key(Sophia::SPGT)

    enum.next.must_equal 'key1'
    enum.next.must_equal 'key2'
    enum.next.must_equal 'key3'
  end

  it 'each_key enumerator SPLT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    enum = @sophia.each_key(Sophia::SPLT)

    enum.next.must_equal 'key3'
    enum.next.must_equal 'key2'
    enum.next.must_equal 'key1'
  end

  it 'each_value SPGT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    vals = []
    @sophia.each_value(Sophia::SPGT) { |v| vals << v }

    vals.must_equal %w[val1 val2 val3]
  end

  it 'each_value SPLT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    vals = []
    @sophia.each_value(Sophia::SPLT) { |v| vals << v }

    vals.must_equal %w[val1 val2 val3].reverse
  end

  it 'each_key enumerator SPGT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    enum = @sophia.each_value(Sophia::SPGT)

    enum.next.must_equal 'val1'
    enum.next.must_equal 'val2'
    enum.next.must_equal 'val3'
  end

  it 'each_key enumerator SPLT' do
    @sophia['key1'] = 'val1'
    @sophia['key2'] = 'val2'
    @sophia['key3'] = 'val3'
    enum = @sophia.each_value(Sophia::SPLT)

    enum.next.must_equal 'val3'
    enum.next.must_equal 'val2'
    enum.next.must_equal 'val1'
  end

  it 'transaction and commit' do
    @sophia.transaction do |sophia|
      sophia['key'] = 'val'
    end

    @sophia['key'].must_equal 'val'
  end

  it 'transaction and rollback' do
    @sophia.transaction do |sophia|
      sophia['key'] = 'val'
      raise 'rollback'
    end rescue nil # ignore exception

    @sophia.wont_include 'key'
  end

  it 'transaction and re-raise' do
    lambda {
      @sophia.transaction do
        raise 'rollback'
      end
    }.must_raise RuntimeError
  end

  it 'transaction with no block' do
    lambda { @sophia.transaction }.must_raise ArgumentError
  end

  it 'double transaction' do
    lambda {
      @sophia.transaction {
        @sophia.transaction {
          @sophia['key'] = 'val'
        }
      }
    }.must_raise SophiaError
  end
end
