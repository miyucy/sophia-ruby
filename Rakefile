require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rbconfig'

DLEXT  = RbConfig::CONFIG['DLEXT']
SOFILE = "sophia.#{DLEXT}"

file "lib/sophia.#{DLEXT}" => Dir['ext/*{.rb,.c}'] do
  Dir.chdir('ext') do
    ruby 'extconf.rb'
    sh 'make'
  end
  cp "ext/sophia.#{DLEXT}", 'lib'
end

Rake::TestTask.new do |t|
  t.warning = true
  t.verbose = true
end
task :test => "lib/sophia.#{DLEXT}"

task :default => :test
