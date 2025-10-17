#!/usr/bin/env ruby
# frozen_string_literal: true
=begin
my_name < email@example.com >

DESCRIPTION:
  Demo skeleton showing ensure-style thread cleanup:
  submit N items, always wait for completion, collect results & errors.

USAGE:
  ruby skeleton.rb 1 2 --required foo --sum --move paper --workers 8 --fail-prob 0.3

LICENSE: ____
=end

require 'optparse'
require 'etc'
# require 'ostruct'

VERSION="0.0.2"

# helpers
class MyError < StandardError; end
class MyExample
  def initialize(opts={})
    @debug = opts[:debug]
    @verbose = opts[:verbose] || 0
  end

  def scolor(msg,color)
    colors = {
      'red'    => "\033[1;31m",
      'norm'   => "\033[0;39m",
      'green'  => "\033[0;32m",
      'blue'   => "\033[0;34m"
    }
    # honor the TTY of the stream we actually use for these messages (stderr)
    if $stderr.tty? || $stdout.tty?
      code = colors[color.downcase] || colors['norm']
      "#{code}#{msg}#{colors['norm']}"
    else
      msg
    end
  end

  def debug(*msg)
    return if not @debug

    $stderr.print scolor('DEBUG: ', 'green')
    if msg[1].to_s > ''
      # val.to_s is called for us:
      $stderr.puts "#{scolor(msg[0], 'blue')} = #{scolor(msg[1..-1].join(' '), 'red')}"
    else
      $stderr.puts "#{scolor(msg.join(' '), 'blue')}"
    end
  end

  def info(*msg)
    prefix = 'INFO: ' unless msg[0] =~ /^\s*INFO:/
    $stderr.puts scolor("#{prefix}#{msg.join(' ')}", "blue")
  end
  alias warn info

  def verbose(msg,level=1)
    return if @verbose <= 0
    puts "#{msg}" if @verbose >= level
  end

  def error(*msg)
    prefix = 'ERROR: ' unless msg[0] =~ /^\s*ERROR:/
    $stderr.puts scolor("#{prefix}#{msg.join(' ')}", "red")
  end
end
# end helpers

# --- CLI parsing -------------------------------------------------------------

def parse_args(argv = ARGV)
  options = {
    accumulate: :max,
    move: nil,
    required: nil,
    workers: nil,
    fail_prob: 0.30,
    seed: nil,
    verbose: 0,  # verbosity level: 0,1,2,...
    debug: ENV.key?('DEBUG') ? true : false,
    integers: []
  }

  parser = OptionParser.new do |op|
    op.banner = "Usage: #{File.basename($PROGRAM_NAME)} N [N ...] [options]"
    op.separator ""
    op.separator "Options:"

    op.on('--sum', 'Sum the integers (default: find the max)') { options[:accumulate] = :sum }
    op.on('--move MOVE', %w[rock paper scissors], 'Choose: rock | paper | scissors') { |m| options[:move] = m }
    op.on('--required VAL', 'A required option') { |v| options[:required] = v }
    op.on('--workers N', Integer, 'Max worker threads (default: auto)') { |n| options[:workers] = n }
    op.on('--fail-prob P', Float, 'Probability a task raises (0.0–1.0)') { |p| options[:fail_prob] = p }
    op.on('--seed SEED', Integer, 'Random seed for reproducibility') { |s| options[:seed] = s }
    # -v can be repeated: -v, -vv, -vvv...
    op.on('-v', '--verbose', 'Increase verbosity (repeat for more)') { options[:verbose] += 1 }
    op.on('-h', '--help', 'Show this help and exit') { puts op; exit 0 }
    op.on('-D', '--debug', 'Show debug messages') { options[:debug] = true; options[:verbose] = 10 }
    op.on_tail('--version', 'Show version') do
      puts VERSION
      exit
    end
  end

  # Capture positional integers
  begin
    parser.parse!(argv)
  rescue OptionParser::MissingArgument => e
    $stderr.puts e.message
    puts parser
    exit 1
  rescue => e
    $stderr.puts "ERROR: #{e.class} #{e.message}"
    exit 2
  end

  options[:integers] = argv.map do |tok|
    Integer(tok)
  rescue ArgumentError
    warn "Non-integer positional argument: #{tok.inspect}"
    exit 2
  end

  if options[:integers].empty?
    warn "At least one positional integer N is required.\n\n#{parser}"
    exit 2
  end

  if options[:required].nil?
    warn "--required is mandatory.\n\n#{parser}"
    exit 2
  end

  if options[:fail_prob] < 0.0 || options[:fail_prob] > 1.0
    warn "--fail-prob must be between 0.0 and 1.0 (got #{options[:fail_prob]})"
    exit 2
  end

  options
end

# --- workload ---------------------------------------------------------------

def handle(item, fail_prob: 0.3)
  # Simulate work; sometimes fail.
  sleep(rand(0.05..0.25))
  raise "boom on #{item}" if rand < fail_prob
  "processed #{item}"
end

# --- orchestration with ensure-style cleanup --------------------------------

def process_all(items, max_workers: nil, fail_prob: 0.3, verbose: false)
  results = []
  errors  = []

  # Choose worker count: user-specified, else number of processors, else 4.
  worker_count = (max_workers && max_workers > 0) ? max_workers : (Etc.respond_to?(:nprocessors) ? Etc.nprocessors : 4)
  worker_count = 1 if worker_count < 1

  job_queue = Queue.new
  items.each { |it| job_queue << it }

  results_lock = Mutex.new
  errors_lock  = Mutex.new

  threads = []

  begin
    worker_count.times do
      threads << Thread.new do
        loop do
          item = nil
          begin
            item = job_queue.pop(true) # non-blocking; raises ThreadError when empty
          rescue ThreadError
            break
          end

          begin
            out = handle(item, fail_prob: fail_prob)
            results_lock.synchronize do
              results << out
              puts "[ok] #{out}" if verbose
            end
          rescue => e
            # Build a traceback-like string
            tb = e.full_message(highlight: false, order: :top)
            errors_lock.synchronize do
              errors << [item, e, tb]
              if verbose
                puts "[err] item=#{item} err=#{e}"
                puts tb
              end
            end
          end
        end
      end
    end
  ensure
    # ensure-style: always join threads and tear down
    threads.each(&:join)
  end

  [results, errors]
end

# --- main -------------------------------------------------------------------

def main(argv = ARGV)
  args = parse_args(argv)

  obj = MyExample.new debug: args[:debug], verbose: args[:verbose]
  $stdout.sync = true

  # demonstrates debug:
  obj.debug('hello', 'world', 'extra')
  obj.error('this', 'is', 'error', 'with', 'extra')
  obj.info('this', 'is', 'info', 'with', 'extra')
  obj.info('this is also info with', 'extra')

  # demonstrates verbose:
  obj.verbose("printing verbose message level 1")
  obj.verbose("printing verbose message level 2", 2)

  # Seed RNG for reproducibility if requested
  srand(args[:seed]) if args[:seed]

  begin
    sum_or_max =
      if args[:accumulate] == :sum
        args[:integers].sum
      else
        args[:integers].max
      end

    items = (0...sum_or_max).to_a

    results, errors = process_all(
      items,
      max_workers: args[:workers],
      fail_prob: args[:fail_prob],
      verbose: args[:verbose] > 0
    )

    puts "Results:"
    results.each { |r| puts "  #{r}" }

    puts "\nErrors:"
    errors.each do |item, exc, tb|
      puts "  item=#{item} err=#{exc}"
      puts tb if args[:verbose] > 0
    end

    if args[:move]
      puts "\nYou played: #{args[:move]}"
    end

    exit(errors.empty? ? 0 : 1)

  rescue Interrupt
    warn "\nInterrupted by user."
    exit 130
  rescue => e
    warn "ERROR: #{e}"
    warn e.full_message(highlight: false, order: :top)
    exit 1
  end
end

if __FILE__ == $PROGRAM_NAME
  main
end
