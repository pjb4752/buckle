require 'optparse'
require 'ostruct'

require 'buckle/compiler'
require 'buckle/exitable'
require 'buckle/repl'
require 'buckle/text_stream'
require 'buckle/version'

module Buckle
  extend Exitable

  def self.parse(arguments)
    options = OpenStruct.new
    options.interactive = false
    options.read = false
    options.compile = false

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'usage: buckle [options]'

      opts.separator ''
      opts.separator 'Specific options:'

      opts.on('-i', '--interactive',
              'Run buckle interactively') do
        options.interactive = true
      end

      opts.on('-r', '--read',
              'Exercise the reader only. Print forms read from stdin') do
        options.read = true
      end

      opts.on('-c', '--compile',
              'Exercise the compiler only. Print bytecode emitted') do
        options.compile = true
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
      run_interactively(options)
    else
      filenames = ARGV
      validate(filenames)
      evaluate(filenames)
    end
  end

  private

  def self.run_interactively(options)
    Repl.new(options).run
  end

  def self.validate(filenames)
    bad_exit('expected filenames') if filenames.empty?
    not_found = filenames.reject { |f| File.exist?(f) }

    unless not_found.empty?
      joined_names = not_found.join(', ')
      bad_exit("bad filename(s): '#{joined_names}'")
    end
  end

  def self.evaluate(filenames)
    filenames.each do |filename|
      input = TextStream.from_file(filename)
      evaluator.evaluate(input)
    end
  end

  def self.evaluator
    @evaluator ||= Evaluator.new
  end
end
