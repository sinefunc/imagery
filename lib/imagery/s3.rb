require 'aws/s3'

module Imagery
  module S3
    def self.included(base)
      class << base
        attr_accessor :s3_bucket, :s3_distribution_domain
      end
    end
    
    S3_HOST = "http://s3.amazonaws.com"

    def url(size = :original)
      if domain = self.class.s3_distribution_domain
        [domain, namespace, key, filename(size)].join('/')
      else
        [S3_HOST, self.class.s3_bucket, namespace, key, filename(size)].join('/')
      end
    end

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
      def store(*args)
        execute(:store, *args)
      end
      module_function :store
      
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
