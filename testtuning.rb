require 'test/unit'
require './vextabparser.rb'

class TestTuning < Test::Unit::TestCase
  def setup
    @tuning = Tuning.new(:e, 5, :b, 4, :g, 4, :d, 4, :a, 3, :e, 3)
  end
  
  def testE
    assert_equal [:e, 5], @tuning.pitch(1, 0)
  end
  
  def testF
    assert_equal [:f, 5], @tuning.pitch(1, 1)
  end
  
  def testGIS
    assert_equal [:gis, 5], @tuning.pitch(1, 4)
  end
  
  def testPitchInHigherOctave
    assert_equal [:e, 6], @tuning.pitch(1, 12)
  end
  
  def testOctave
    assert_equal 4, Note.new(2, 2).octave(@tuning), "A played on G string"
  end
end