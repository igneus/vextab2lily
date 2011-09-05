require "./vextabparser.rb"
require "./lilypondgenerator.rb"

require "optparse"

options = {
  :run_lilypond => false,
  :to_file => nil,
  :verbose => false
}

OptionParser.new do |opts|
  opts.on("-l", "--run-lilypond", "output to file and run LilyPond on it") do
    options[:run_lilypond] = true
    unless options[:to_file]
      options[:to_file] = true
    end
  end
  
  opts.on("-o", "--output [FILE]", "Output to file; default name is name of input file + .ly") do |f|
    if f then
      options[:to_file] = f
    end
  end
  
  opts.on("-v", "--verbose", "Verbose output") do
    options[:verbose] = true
  end
  
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

if ARGV.empty? then
  raise "No input file defined. Please, supply file name as commandline argument."
end

if options[:to_file] == true then
  # output to file, but file name hasn't been explicitly defined
  
  if m = ARGV[0].match(/^(?<name>.+)\.[a-zA-Z]+$/) then
    options[:to_file] = m[:name]+".ly"
  else
    options[:to_file] = ARGV[0]+".ly"
  end
end

if options[:to_file] then
  outstream = File.open options[:to_file], "w"
else
  outstream = STDOUT
end

generator = LilyPondGenerator.new
generator.generate(VexTabParser.new.parse(File.readlines(ARGV[0])), outstream)

if outstream.is_a? File then
  outstream.close
  puts "Output written to file '#{options[:to_file]}'."  if options[:verbose]
end

if options[:run_lilypond] then
  puts "Running Lilypond" if options[:verbose]
  exec "lilypond", options[:to_file]
end