require "./vextabparser.rb"
require "./lilypondgenerator.rb"

generator = LilyPondGenerator.new
generator.generate(VexTabParser.new.parse(File.readlines(ARGV[0])))