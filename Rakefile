libdir = File.expand_path('lib', File.dirname(__FILE__))
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include? libdir

require 'bundler/setup'
require 'kirschtorte'
require 'resque/tasks'

task :default => ["resque:workers"]
