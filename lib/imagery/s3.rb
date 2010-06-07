require 'aws/s3'

module Imagery
  module S3
    def self.included(base)
      base.extend Configs
      class << base
        attr_writer :s3_bucket, :s3_distribution_domain, :s3_host
      end
    end

    module Configs
      def s3_bucket(bucket = nil)
        @s3_bucket = bucket  if bucket
        @s3_bucket || raise(UndefinedBucket, BUCKET_ERROR_MSG)
      end

      BUCKET_ERROR_MSG = (<<-MSG).gsub(/^ {6}/, '')

      You need to define a bucket name. Example:

      class Imagery::Model
        include Imagery::S3

        s3_bucket 'my-bucket-name'
      end
      MSG

      def s3_distribution_domain(domain = nil)
        @s3_distribution_domain = domain  if domain
        @s3_distribution_domain
      end
  
      # Allows you to customize the S3 host. Usually happens when you use
      # amazon S3 EU.
      #
      # @param [String] host the custom host you want to use instead.
      # @return [String] the s3 host currently set.
      def s3_host(host = nil)
        @s3_host = host  if host
        @s3_host || S3_HOST
      end
    end
  
    UndefinedBucket = Class.new(StandardError)

    S3_HOST = "http://s3.amazonaws.com"

    # Returns a url publicly accessible. If a distribution domain is set,
    # then the url will be based on that.
    #
    # @example
    #   
    #   class Imagery::Model
    #     include Imagery::S3
    #
    #     s3_bucket 'bucket-name'
    #   end
    #   
    #   Photo = Class.new(Struct.new(:id))
    #   i = Imagery.new(Photo.new(1001))
    #
    #   i.url == 'http://s3.amazonaws.com/bucket-name/photo/1001/original.png'
    #   # => true
    #
    #   Imagery::Model.s3_distribution_domain = 'assets.site.com'
    #   i.url == 'http://assets.site.com/photo/1001/original.png'
    #   # => true
    #
    #   # You may also subclass this of course since it's just a ruby object
    #   # and configure them differently as needed.
    #
    #   class CloudFront < Imagery::Model
    #     include Imagery::S3
    #     s3_bucket 'cloudfront'
    #     s3_distribution_domain 'assets.site.com'
    #   end
    #
    #   class RegularS3 < Imagery::Model
    #     include Imagery::S3
    #     s3_bucket 'cloudfront'
    #   end
    #
    # @param [Symbol] size the preferred size you want for the url.
    # @return [String] the size specific url.
    def url(size = self.default_size)
      if domain = self.class.s3_distribution_domain
        [domain, namespace, key, filename(size)].join('/')
      else
        [self.class.s3_host, self.class.s3_bucket, namespace, key, filename(size)].join('/')
      end
    end

    # In addition to saving the files and resizing them locally, uploads all
    # the different sizes to amazon S3.
    def save(io)
      if super
        s3_object_keys.each do |key, size|
          Gateway.store(key,
            File.open(file(size)),
            self.class.s3_bucket,
            :access => :public_read,
            :content_type => "image/png"
          )
        end
      end
    end

    # Deletes all the files related to this Imagery instance and also
    # all the S3 keys.
    def delete
      super
      s3_object_keys.each do |key, size|
        Gateway.delete key, self.class.s3_bucket
      end
    end

  protected
    def s3_object_keys
      sizes.keys.map do |size|
        [[namespace, key, filename(size)].join('/'), size]
      end
    end

    module Gateway
      # A wrapper for AWS::S3::S3Object.store. Basically auto-connects
      # using the environment vars.
      #
      # @example
      #   
      #   AWS::S3::Base.connected?
      #   # => false
      #
      #   Imagery::S3::Gateway.store(
      #     'avatar', File.open('avatar.jpg'), 'bucket'
      #   )
      #   AWS::S3::Base.connected?
      #   # => true
      #       
      def store(*args)
        execute(:store, *args)
      end
      module_function :store
      
      # A wrapper for AWS::S3::S3Object.delete. Basically auto-connects
      # using the environment vars.
      #
      # @example
      #   
      #   AWS::S3::Base.connected?
      #   # => false
      #
      #   Imagery::S3::Gateway.delete('avatar', 'bucket')
      #   AWS::S3::Base.connected?
      #   # => true
      def delete(*args)
        execute(:delete, *args)
      end
      module_function :delete
    
    private
      def execute(command, *args)
        begin
          AWS::S3::S3Object.__send__(command, *args)
        rescue AWS::S3::NoConnectionEstablished
          AWS::S3::Base.establish_connection!(
            :access_key_id     => ENV["AMAZON_ACCESS_KEY_ID"],
            :secret_access_key => ENV["AMAZON_SECRET_ACCESS_KEY"]
          )
          retry
        end
      end
      module_function :execute
    end
  end
end
