require 'buckle/compilation'
require 'buckle/version'

module Buckle
  def self.run
    validate(filenames)
    compile(filenames)
  end

  private

  def self.validate(filenames)
    bad_exit('expected filenames') if filenames.empty?
    not_found = filenames.reject { |f| File.exist?(f) }

    unless not_found.empty?
      joined_names = not_found.join(', ')
      bad_exit "bad filename(s): '#{joined_names}'"
    end
  end

  def self.filenames
    ARGV
  end

  def self.compile(filenames)
    filenames.each do |filename|
      compile_file(filename)
    end
  end

  def self.compile_file(filename)
    File.open(filename, 'r') do |input|
      Compilation.compile(input)
    end
  end

  def self.bad_exit(message, status: 1)
    $stderr.puts "err: #{message}"
    exit status
  end
end
