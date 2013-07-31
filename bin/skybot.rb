#!/usr/bin/env ruby
ROOT_DIR = File.expand_path(File.dirname(File.dirname(__FILE__)))
$LOAD_PATH.unshift(ROOT_DIR)
require 'lib/skybot'

Skybot::Runner.start