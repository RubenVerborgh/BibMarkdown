# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'juwelier'
Juwelier::Tasks.new do |gem|
  gem.name = "bibmarkdown"
  gem.homepage = "http://github.com/RubenVerborgh/bibmarkdown"
  gem.license = "MIT"
  gem.summary = "Markdown with BibTeX citations."
  gem.email = "ruben@verborgh.org"
  gem.authors = ["Ruben Verborgh"]
end
Juwelier::RubygemsDotOrgTasks.new
