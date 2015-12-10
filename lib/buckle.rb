require 'optparse'
require 'ostruct'

require 'buckle/exitable'
require 'buckle/file_compiler'
require 'buckle/repl'
require 'buckle/version'

module Buckle
  extend Exitable

  def self.parse(arguments)
    options = OpenStruct.new
    options.interactive = false

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'usage: buckle [options]'

      opts.separator ''
      opts.separator 'Specific options:'

      opts.on('-i', '--interactive',
              'Run the buckle compiler interactively') do |i|
        options.interactive = true
      end

      opts.separator ''
      opts.separator 'Common options:'

      opts.on_tail('-h', '--help', 'Show this message') do
        puts opts
        exit
      end

      opts.on_tail('--version', 'Show version') do
        puts Buckle::Version
        exit
      end
    end

    opt_parser.parse!
    options
  end

  def self.run(arguments = ARGV)
    options = parse(arguments)

    if options.interactive
      run_interactively
    else
      filenames = ARGV
      validate(filenames)
      compile(filenames)
    end
  end

  private

  def self.run_interactively
    Repl.new.run
  end

  def self.validate(filenames)
    bad_exit('expected filenames') if filenames.empty?
    not_found = filenames.reject { |f| File.exist?(f) }

    unless not_found.empty?
      joined_names = not_found.join(', ')
      bad_exit("bad filename(s): '#{joined_names}'")
    end
  end

  def self.compile(filenames)
    FileCompiler.new(filenames).compile
  end
end
