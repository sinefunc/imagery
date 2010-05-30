Imagery
=======

(See documentation at [http://labs.sinefunc.com/imagery/doc](http://labs.sinefunc.com/imagery/doc))

## Image manipulation should be simple. It should be customizable. It should allow for flexibility. Imagery attempts to solve these.

### Imagery favors:

1. Simplicity and explicitness over magic DSLs.
2. OOP principles such as inheritance and composition.
3. Flexibility and extensibility.
4. Not being tied to any form of ORM.

1. Simplicity and Explicitness
------------------------------
To get started using Imagery you only need ImageMagick, ruby and Imagery of 
course.
    
    # on debian based systems
    sudo apt-get install imagemagick
    # or maybe using macports
    sudo port install ImageMagick
    [sudo] gem install imagery

Then you may proceed using it.
  
    require 'rubygems'
    require 'imagery'

    Photo = Class.new(Struct.new(:id))
    
    i = Imagery.new(Photo.new(1001))
    i.root = '/some/path/here'
    i.sizes = { :thumb => ["48x48^", "48x48"], :large => ["480x320"] }
    i.save(File.open('/some/path/to/image.jpg'))

    File.exist?('/some/path/here/public/system/photo/1001/thumb.png')
    # => true

    File.exist?('/some/path/here/public/system/photo/1001/large.png')
    # => true

    File.exist?('/some/path/here/public/system/photo/1001/original.png')
    # => true

    # the defaut is to use the .id and the name of the class passed,
    # but you can specify a different scheme.

    i = Imagery.new(Photo.new(1001), `uuidgen`.strip, "photos")
    i.root = '/some/path/here'
    i.file == '/some/path/here/public/system/photos/1c2030a6-6bfa-11df-8997-67a71f1f84c7/original.png'
    # => true

2. OOP Principles (that we already know)
----------------------------------------

### Ohm example (See [http://ohm.keyvalue.org](http://ohm.keyvalue.org))
    
    # Imagery will use ROOT_DIR if its available
    ROOT_DIR = "/u/apps/site/current"

    class User < Ohm::Model
      include Ohm::Callbacks
      
      after :save, :write_avatar

      def avatar=(fp)
        @avatar_fp = fp
      end

      def avatar
        @avatar ||= 
          Imagery.new(self).tap do |i|
            i.sizes = { :thumb => ["48x48^", "48x48"], :medium => ["120x120"] }
          end
      end

    protected
      def write_avatar
        avatar.save(@avatar_fp[:tempfile])  if @avatar_fp
      end
    end

    # Since we're using composition, we can customize the dimensions on an 
    # instance level.
    class Collage < Ohm::Model
      attribute :width
      attribute :height

      def photo
        @photo ||= 
          Imagery.new(self).tap do |i|
            i.sizes = { :thumb => ["%sx%s" % [width, height]] }
          end
      end
    end
    
    # For cases where we want to use S3 for some and normal filesystem for others
    class S3Photo < Imagery::Model
      include Imagery::S3
      self.s3_bucket = 'my-bucket'
    end

    # then maybe some other files are using cloudfront
    class CloudfrontPhoto < Imagery::Model
      include Imagery::S3
      self.s3_bucket = 'my-bucket'
      self.s3_distribution_domain = 'assets.site.com'
    end

3. Flexibility and Extensibility
--------------------------------
### Existing plugins: Faking and S3

#### Imagery::S3

As was shown in some examples above you can easily do S3 integration.
The access credentials are assumed to be stored in

    ENV["AMAZON_ACCESS_KEY_ID"]
    ENV["AMAZON_SECRET_ACCESS_KEY"]

you can do this by setting it on your .bash_profile / .bashrc or just
manually setting them somewhere in your appication

    ENV["AMAZON_ACCESS_KEY_ID"] = '_access_key_id_'
    ENV["AMAZON_SECRET_ACCESS_KEY"] = '_secret_access_key_'

Now you can just start using it:
  
    Photo = Class.new(Struct.new(:id))

    class Imagery::Model
      include Imagery::S3
      self.s3_bucket = 'my-bucket'
    end

    i = Imagery.new(Photo.new(1001))
    i.root = '/tmp'
    i.save(File.open('/some/path/to/image.jpg'))

#### Imagery::Faking

When doing testing, you definitely don't want to run image
resizing everytime. Enter Faking.

    # in your test_helper / spec_helper
    Imagery::Model.send :include, Imagery::Faking
    Imagery::Model.mode = :fake
  
    # but what if we want to run it for real on a case to case basis?
    # sure we can!
    Imagery::Model.real {
      # do some imagery testing here
    }

#### Imagery::Test

There is a module you can include in your test context to automate the pattern
of testing / faking on an opt-in basis.

    # in your test_helper / spec_helper
    class Test::Unit::TestCase
      include Imagery::Test
    end
    
    # now when you do some testing... (User assumes the user example above)
    imagery do |is_real|
      user = User.new(:avatar => { tempfile: File.open('avatar.jpg') })
      user.save

      if is_real
        assert File.exist?(user.avatar.file)
      end
    end

Running your test suite:

    REAL_IMAGERY=true rake test

It's off by default though, so you don't have to do anything to make sure 
Imagery doesn't run.

### Extending Imagery
By making use of standard Ruby idioms, we can easily do lots with it. 
Exensibility is addressed via Ruby modules for example:

    module Imagery
      module MogileStore
        def self.included(base)
          class << base
            attr_accessor :mogile_config
          end
        end

        def save(io)
          if super
            # do some mogie FS stuff here
          end
        end

        def delete
          super
          # remove the mogile stuff here
        end
      end
    end

    # Now just include the module however, whenever you want
    module Imagery
      class Model
        include Imagery::MogileStore
        self.mogile_config = { :foo => :bar }
      end
    end


### Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

### Copyright

Copyright (c) 2010 Cyril David. See LICENSE for details.
