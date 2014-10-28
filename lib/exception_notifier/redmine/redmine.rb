require 'action_dispatch'
require 'httparty'
require 'json'

module ExceptionNotifier
  
  class RedmineNotifier

    def initialize(config)
      @config = config
    end

    def call(exception, options={})
      env = options[:env]
      issue = compose_issue(options, exception)
      create_issue(issue) unless issue_exist?(issue)
    end

    private

    def compose_issue(options, exception)
      env = options[:env]

      unless env.nil?
        options[:body] ||= {}
        options[:body][:server] = Socket.gethostname
        options[:body][:process] = $$
        options[:body][:rails_root] = Rails.root if defined?(Rails)
        options[:body][:exception] = { :error_class => exception.class.to_s,
                                       :message => exception.message.inspect,
                                       :backtrace => exception.backtrace }
        options[:body][:data] = (env['exception_notifier.exception_data'] || {}).merge(options[:data] || {})

        issue = {}
        issue[:project_id] = @config[:project_id]
        issue[:tracker_id] = @config[:tracker_id]
        issue[:status_id] = @config[:status_id]
        issue[:priority_id] = @config[:priority_id]
        issue[:assigned_to_id] = @config[:assigned_to_id]
        issue[:subject] = compose_subject(options, exception)
        issue[:custom_fields] = [{ :id    => @config[:x_checksum_cf_id],
                                   :value => encode_subject(issue[:subject])}]
        issue[:description] = options[:body][:exception].inspect
        issue
      end
    end

    def compose_subject(options, exception)
      env = options[:env]
      kontroller = env['action_controller.instance'] || MissingController.new
      subject = "#{kontroller.controller_name}##{kontroller.action_name}" if kontroller
      subject << " (#{exception.class})"
      subject << " #{exception.message.inspect}" if options[:verbose_subject]
      subject.length > 120 ? subject[0...120] + "..." : subject
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
      raise "Unexpected Response" if response.nil? || response["total_count"].nil?
      response["total_count"] > 0
    end

    def encode_subject(subject)
      Digest::SHA2.hexdigest(subject)
    end
  end
end
