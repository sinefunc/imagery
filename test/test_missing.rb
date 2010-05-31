require "helper"

class MissingTest < Test::Unit::TestCase
  Photo = Class.new(Struct.new(:id))

  test "adding it using extend" do
    imagery = Imagery.new(Photo.new(1001))
    imagery.extend Imagery::Missing
    imagery.existing = ""
    assert_equal '/missing/photo/original.png', imagery.url
  end
  
  class WithMissing < Imagery::Model
    include Imagery::Missing
  end

  test "adding it using include" do
    imagery = WithMissing.new(Photo.new(1001))
    imagery.existing = ""

    assert_equal '/missing/photo/original.png', imagery.url
  end

  test "still returns as normal when not missing" do
    imagery = WithMissing.new(Photo.new(1001))
    imagery.root = '/tmp'
    imagery.existing = 'lake.jpg'
    assert_equal '/system/photo/1001/original.png', imagery.url
  end
end
