require 'rubygems'
require 'test/unit'
require 'contest'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'imagery'

class Test::Unit::TestCase
  FIXTURES = File.dirname(__FILE__) + '/fixtures'
end
