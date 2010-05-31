require "helper"

class WithS3Test < Test::Unit::TestCase
  class WithS3 < Imagery::Model
    include Imagery::Faking
    include Imagery::S3

    self.s3_bucket = "tmp-bucket-name"
  end

  class NoBucket < Imagery::Model
    include Imagery::Faking
    include Imagery::S3
  end

  SuperSecretPhoto = Class.new(Struct.new(:id))
  
  test "urls" do
    imagery = WithS3.new(SuperSecretPhoto.new(1001))
    imagery.root = '/tmp'
    imagery.sizes = {
      :thumb => ["56x56^"],
      :small => ["100x100^", "100x100"],
      :large => ["200x200>", "200x200"]
    }
    
    s = 'http://s3.amazonaws.com/tmp-bucket-name/supersecretphoto/1001/%s.png'

    assert_equal s % 'original', imagery.url
    assert_equal s % 'original', imagery.url(:original)
    assert_equal s % 'thumb', imagery.url(:thumb)
    assert_equal s % 'small', imagery.url(:small)
    assert_equal s % 'large', imagery.url(:large)
  end

  test "url when no bucket" do
    imagery = NoBucket.new(SuperSecretPhoto.new(1001))
    imagery.sizes = {
      :thumb => ["56x56^"],
      :small => ["100x100^", "100x100"],
      :large => ["200x200>", "200x200"]
    }

    assert_raise Imagery::S3::UndefinedBucket do
      imagery.url 
    end

    begin
      imagery.url
    rescue Imagery::S3::UndefinedBucket => e
      assert_equal Imagery::S3::Configs::BUCKET_ERROR_MSG, e.message
    end
  end

  test "urls with a distribution domain" do
    imagery = WithS3.new(SuperSecretPhoto.new(1001))
    imagery.root = '/tmp'
    imagery.sizes = {
      :thumb => ["56x56^"],
      :small => ["100x100^", "100x100"],
      :large => ["200x200>", "200x200"]
    }
    
    s = 'http://assets.site.com/supersecretphoto/1001/%s.png'
    
    WithS3.s3_distribution_domain = 'http://assets.site.com'

    assert_equal s % 'original', imagery.url
    assert_equal s % 'original', imagery.url(:original)
    assert_equal s % 'thumb', imagery.url(:thumb)
    assert_equal s % 'small', imagery.url(:small)
    assert_equal s % 'large', imagery.url(:large)

    WithS3.s3_distribution_domain = nil
  end

  test "saving and storing" do
    imagery = WithS3.new(SuperSecretPhoto.new(1001))
    imagery.root = '/tmp'
    imagery.sizes = {
      :thumb => ["56x56^"],
      :small => ["100x100^", "100x100"],
      :large => ["200x200>", "200x200"]
    }

    File.stubs(:open).returns(:contents)

    Imagery::S3::Gateway.expects(:store).with() { |key, io, bucket, hash|
      key == "supersecretphoto/1001/thumb.png" && bucket == 'tmp-bucket-name' &&
        hash[:access] == :public_read && hash[:content_type] == 'image/png' &&
        io == :contents
    }

    Imagery::S3::Gateway.expects(:store).with() { |key, io, bucket, hash|
      key == "supersecretphoto/1001/small.png" && bucket == 'tmp-bucket-name' &&
        hash[:access] == :public_read && hash[:content_type] == 'image/png' &&
        io == :contents
    }

    Imagery::S3::Gateway.expects(:store).with() { |key, io, bucket, hash|
      key == "supersecretphoto/1001/large.png" && bucket == 'tmp-bucket-name' &&
        hash[:access] == :public_read && hash[:content_type] == 'image/png' &&
        io == :contents
    }
  
    Imagery::S3::Gateway.expects(:store).with() { |key, io, bucket, hash|
      key == "supersecretphoto/1001/original.png" && bucket == 'tmp-bucket-name' &&
        hash[:access] == :public_read && hash[:content_type] == 'image/png' &&
        io == :contents
    }
    
    WithS3.faked do
      assert imagery.save(File.open(FIXTURES + '/lake.jpg'))
    end
  end

  test "deleting" do
    imagery = WithS3.new(SuperSecretPhoto.new(1001))
    imagery.root = '/tmp'
    imagery.sizes = {
      :thumb => ["56x56^"],
      :small => ["100x100^", "100x100"],
      :large => ["200x200>", "200x200"]
    }

    Imagery::S3::Gateway.expects(:delete).
      with('supersecretphoto/1001/thumb.png', 'tmp-bucket-name')

    Imagery::S3::Gateway.expects(:delete).
      with('supersecretphoto/1001/small.png', 'tmp-bucket-name')

    Imagery::S3::Gateway.expects(:delete).
      with('supersecretphoto/1001/large.png', 'tmp-bucket-name')

    Imagery::S3::Gateway.expects(:delete).
      with('supersecretphoto/1001/original.png', 'tmp-bucket-name')

    assert imagery.delete
  end
end
