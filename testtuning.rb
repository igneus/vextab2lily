require 'test/unit'
require './vextabparser.rb'

class TestTuning < Test::Unit::TestCase
  def setup
    @tuning = Tuning.new(:e, 2, :b, 2, :g, 2, :d, 1, :a, 1, :e, 1)
  end
  
  def testE
    assert_equal [:e, 2], @tuning.pitch(0, 0)
  end
  
  def testF
    assert_equal [:f, 2], @tuning.pitch(0, 1)
  end
  
  def testGIS
    assert_equal [:gis, 2], @tuning.pitch(0, 4)
  end
  
  def testOctave
    assert_equal [:e, 3], @tuning.pitch(0, 12)
  end
end