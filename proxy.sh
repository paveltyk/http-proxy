#!/usr/bin/env ruby
# Copyright 2013 Pavel Tsiukhtsiayeu https://github.com/PavelTyk/
require 'socket'
require 'uri'
require File.expand_path('../http_proxy_server.rb', __FILE__)
require File.expand_path('../logger.rb', __FILE__)
require File.expand_path('../http_header.rb', __FILE__)

HTTPProxyServer.new(ARGV[0]).run
