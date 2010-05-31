require 'helper'
require 'benchmark'

class Imagery::Model
  include Imagery::Faking
end

class TestImagery < Test::Unit::TestCase
  Photo = Class.new(Struct.new(:id))

  test "namespace" do
    assert_equal 'photo', Imagery.new(Photo.new(1001)).namespace
  end

  test "key" do
    assert_equal '1001', Imagery.new(Photo.new(1001)).key
  end

  test "root_path when root not defined" do
    imagery = Imagery.new(Photo.new(1001))
    
    assert_raise Imagery::Model::UndefinedRoot do
      imagery.file
    end
  end

  test "root_path when no ROOT_DIR" do
    imagery = Imagery.new(Photo.new(1001))
    imagery.root = '/'
    assert_equal "/public/system/photo/1001/tmp", imagery.send(:tmp)
  end

  test "root_path when ROOT_DIR defined on imagery" do
    Imagery::ROOT_DIR = '/root/dir'

    imagery = Imagery.new(Photo.new(1001))
    assert_equal "/root/dir/public/system/photo/1001/tmp", imagery.send(:tmp)

    Imagery.send :remove_const, :ROOT_DIR
  end

  test "root_path when ROOT_DIR defined on object" do
    Object::ROOT_DIR = '/root/dir'

    imagery = Imagery.new(Photo.new(1001))
    assert_equal "/root/dir/public/system/photo/1001/tmp", imagery.send(:tmp)

    Object.send :remove_const, :ROOT_DIR
  end
  
  describe "file" do
    setup do
      @imagery = Imagery.new(Photo.new(1001))
      @imagery.root = '/r/d'
      @imagery.sizes = { :thumb => ['10x10'] }
    end

    test "file by default" do
      assert_equal "/r/d/public/system/photo/1001/original.png", @imagery.file
    end

    test "file given a size" do
      assert_equal "/r/d/public/system/photo/1001/thumb.png", @imagery.file(:thumb)
    end
  end

  describe "convert" do
    setup do
      @imagery = Imagery.new(Photo.new(1001))
      @imagery.root = '/r/d'
      @imagery.sizes = {
        :thumb => ["56x56^"],
        :small => ["56x56^", "56x56"]
      }
    end

    test "default resize" do
      expected = 
        "convert /r/d/public/system/photo/1001/tmp -thumbnail '56x56^' " +
        "-gravity center /r/d/public/system/photo/1001/thumb.png"

      assert_equal expected, @imagery.send(:cmd, :thumb),
    end

    test "resize with extent param" do
      expected = 
        "convert /r/d/public/system/photo/1001/tmp -thumbnail '56x56^' " +
        "-gravity center -extent 56x56 /r/d/public/system/photo/1001/small.png"

      assert_equal expected, @imagery.send(:cmd, :small)
    end
  end

  describe "saving" do
    setup do
      @imagery = Imagery.new(Photo.new(1001))
      @imagery.root = '/tmp'
      @imagery.sizes = {
        :thumb => ["56x56^"],
        :small => ["100x100^", "100x100"],
        :large => ["200x200>", "200x200"]
      }
    end

    teardown do
      FileUtils.rm_rf '/tmp/public'
    end
    
    test "writes all the different geometry sizes normally" do
      assert @imagery.save(File.open(FIXTURES + '/lake.jpg'))
    
      assert File.exist?(@imagery.file)
      assert File.exist?(@imagery.file(:thumb))
      assert File.exist?(@imagery.file(:small))
      assert File.exist?(@imagery.file(:large))
    end

    test "able to delete them" do
      @imagery.save(File.open(FIXTURES + '/lake.jpg'))
      @imagery.delete

      assert ! File.exist?(@imagery.file)
      assert ! File.exist?(@imagery.file(:thumb))
      assert ! File.exist?(@imagery.file(:small))
      assert ! File.exist?(@imagery.file(:large))
    end

    test "when mode == :fake" do
      time = Benchmark.realtime { 
        Imagery::Model.faked { 
          assert @imagery.save(File.open(FIXTURES + '/lake.jpg'))
        }
      }

      assert time < 0.01, "Faked context should run in less than 0.01 secs"
    end
  end

  describe "url" do
    setup do
      @imagery = Imagery.new(Photo.new(1001))
      @imagery.root = '/tmp'
      @imagery.sizes = { :small => ["40x40"] }
    end

    test "original" do
      assert_equal '/system/photo/1001/original.png', @imagery.url
    end

    test "small" do
      assert_equal '/system/photo/1001/small.png', @imagery.url(:small)
    end

    test "non-existent" do
      assert_raise Imagery::Model::UnknownSize do
        @imagery.url(:foo)
      end
    end
  end
end
