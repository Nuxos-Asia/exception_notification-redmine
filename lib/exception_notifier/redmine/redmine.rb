require 'action_dispatch'
require 'httparty'
require 'json'
require 'erb'
require 'pp'

module ExceptionNotifier
  class RedmineNotifier
    module Redmine
      class MissingController
        def method_missing(*args, &block)
        end
      end
    end

    def initialize(config)
      @config = config
    end

    def call(exception, options={})
      unless options[:env].nil?
        compose_data(options[:env], exception, options)
        issue = compose_issue
        create_issue(issue) unless issue_exist?(issue)
      end
    end

    private

    def compose_data(env, exception, options = {})
      @env        = env
      @exception  = exception
      @options    = options
      @kontroller = env['action_controller.instance'] || Redmine::MissingController.new
      @request    = ActionDispatch::Request.new(env)
      @backtrace  = exception.backtrace ? clean_backtrace(exception) : []
      @data       = (env['exception_notifier.exception_data'] || {}).merge(options[:data] || {})
    end

    def compose_issue
      issue = {}
      issue[:project_id] = @config[:project_id]
      issue[:tracker_id] = @config[:tracker_id]
      issue[:status_id] = @config[:status_id]
      issue[:priority_id] = @config[:priority_id]
      issue[:assigned_to_id] = @config[:assigned_to_id] unless @config[:assigned_to_id].nil?
      issue[:fixed_version_id] = @config[:fixed_version_id] unless @config[:fixed_version_id].nil?
      issue[:subject] = compose_subject
      issue[:custom_fields] = [{ :id    => @config[:x_checksum_cf_id],
                                 :value => encode_subject(issue[:subject])}]
      issue[:description] = compose_description
      issue
    end

    def compose_subject
      subject = "#{@config[:issues_prefix]} " || "[Error] "
      subject << "#{@kontroller.controller_name}##{@kontroller.action_name}" if @kontroller
      subject << " (#{@exception.class})"
      subject << " #{@exception.message.inspect}" if @options[:verbose_subject]
      subject.length > 120 ? subject[0...120] + "..." : subject
    end

    def compose_description
      template_path = "#{File.dirname(__FILE__)}/views/exception_notifier/issue.text.erb"
      template = File.open(template_path, "r").read
      ERB.new(template, nil, '-').result(binding)
    end

    def issues_url(params = {})
      default_params = { :key => @config[:api_key] }
      encoded_params = URI.encode_www_form(default_params.merge(params))
      "#{@config[:host_url]}/#{@config[:issues_url]}?#{encoded_params}"
    end

    def create_issue(issue)
      options = { :body => { :issue => issue }.to_json,
                  :headers => { "Content-Type" => "application/json" } }
      response = ::HTTParty.send(:post, issues_url, options)
    end

    def issue_exist?(issue)
      x_checksum = issue[:custom_fields][0][:value]
      response = ::HTTParty.send(:get, issues_url("project_id" => @config[:project_id],
                                                  "cf_#{@config[:x_checksum_cf_id]}" => x_checksum))
      if response.nil? || response["total_count"].nil?
        Rails.logger.debug "Received unexpected response: #{response.inspect}"
        raise "Unexpected Response"
      end
      response["total_count"] > 0
    end

    def encode_subject(subject)
      Digest::SHA2.hexdigest(subject)
    end

    def clean_backtrace(exception)
      if defined?(Rails) && Rails.respond_to?(:backtrace_cleaner)
        Rails.backtrace_cleaner.send(:filter, exception.backtrace)
      else
        exception.backtrace
      end
    end
  end
end
