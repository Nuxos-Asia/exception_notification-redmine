# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'exception_notification/redmine/version'

Gem::Specification.new do |s|
  s.name = 'exception_notification-redmine'
  s.version       = ExceptionNotification::Redmine::VERSION
  s.authors = ["Richard Piacentini", "Suttipong Wisittanakorn"]
  s.date = "2017-04-05"
  s.summary = "This gem add a Redmine notifier to Exception Notification"
  s.description = "This Ruby gem is an extension of the exception_notification gem to support creating issues in Redmine"
  s.homepage = "https://github.com/Nuxos-Asia/exception_notification-redmine"
  s.email = ["richard.piacentini@nuxos.asia", "safe@nuxos.asia"]
  s.license = "MIT"

  s.post_install_message = "*** Please read the README.MD file to setup the Redmine Notifier."

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency("exception_notification", "~> 4.0")
  s.add_dependency("httparty", "~> 0.10")
  s.add_dependency("json", ">= 1.8")

  s.add_development_dependency "bundler", "~> 1.7"
  s.add_development_dependency "rake", ">= 10.0"

end
