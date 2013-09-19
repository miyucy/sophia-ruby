require 'mkmf'

dir_config 'sophia'

unless have_library('sophia')
  require 'fileutils'

  f = File.dirname(File.expand_path __FILE__)
  g = File.expand_path '../../vendor/sophia/db/*.{c,h}', __FILE__
  Dir[g].each { |e| FileUtils.copy e, f }
end

create_makefile 'sophia'
