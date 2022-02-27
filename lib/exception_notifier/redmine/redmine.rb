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
        old_issues = issue_exist?(issue)
        if old_issues["total_count"] > 0
          update_existing(old_issues)
        else
          create_issue(issue)
        end
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
      if @config[:x_hit_count_cf_id] == nil or @config[:x_hit_count_cf_id] == ""
        issue[:custom_fields] = [{ :id    => @config[:x_checksum_cf_id],
                                   :value   => encode_subject(issue[:subject])}]
      else
        issue[:custom_fields] = [{ :id    => @config[:x_checksum_cf_id],
                                   :value => encode_subject(issue[:subject])},
                                 { :id    => @config[:x_hit_count_cf_id],
                                   :value => 1}]
      end
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
      if @config[:formatting] == "textile"
        template_path = "#{File.dirname(__FILE__)}/views/exception_notifier/issue.text.erb"
      else
        template_path = "#{File.dirname(__FILE__)}/views/exception_notifier/issue.md.text.erb"
      end
      template = File.open(template_path, "r").read
      ERB.new(template, nil, '-').result(binding)
    end

    def issues_url(params = {})
      default_params = { :key => @config[:api_key] }
      encoded_params = URI.encode_www_form(default_params.merge(params))
      if not @config[:request_format] == nil
        "#{@config[:host_url]}/#{@config[:issues_url]}.#{@config[:request_format]}?#{encoded_params}"
      else
        "#{@config[:host_url]}/#{@config[:issues_url]}?#{encoded_params}"
      end
    end
    def update_url(params = {}, issue_id)
      default_params = { :key => @config[:api_key] }
      encoded_params = URI.encode_www_form(default_params.merge(params))
      "#{@config[:host_url]}/#{@config[:issues_url]}/#{issue_id}.#{@config[:request_format]}?#{encoded_params}"
    end
    def create_issue(issue)
      options = { :body => { :issue => issue }.to_json,
                  :headers => { "Content-Type" => "application/json" } }
      ::HTTParty.send(:post, issues_url, options)
    end

    def issue_exist?(issue)
      x_checksum = issue[:custom_fields][0][:value]
      response = ::HTTParty.send(:get, issues_url("project_id" => @config[:project_id],
                                                  "cf_#{@config[:x_checksum_cf_id]}" => x_checksum,
                                                  "status_id" => "*"))
      if response.nil? || response["total_count"].nil?
        Rails.logger.debug "Received unexpected response: #{response.inspect}"
        raise "Unexpected Response"
      end
      return response
    end
    def update_existing(old_issue)
      if @config[:x_hit_count_cf_id] == nil or @config[:x_hit_count_cf_id] == ""
        puts "Hit count option not specified. Will not update"
      else
        hit_count = 0
        old_issue["issues"][0]["custom_fields"].each do |custom|
          if custom["id"] == @config[:x_hit_count_cf_id].to_i
            hit_count = custom["value"].to_i + 1
            break
          end
        end
        issue = {}
        old_issue["issues"][0]["status"]["id"]
        if not (@config[:reopen_issue_if_closed] == nil or @config[:reopen_issue_if_closed] == "")
          if @config[:reopen_issue_if_closed][1].include?(old_issue["issues"][0]["status"]["id"]) == true
            issue[:status_id] = @config[:reopen_issue_if_closed][0]
          elsif @config[:reopen_issue_if_closed][2] == old_issue["issues"][0]["status"]["id"].to_i
            puts "WontFix Set. Skipping Updating"
            return "WONTFIX"
          end
        end


        if @config[:add_note_on_update] == true
          issue[:notes] = compose_description
        end
        issue[:custom_fields] = [{ :value => hit_count,
                                   :id    => @config[:x_hit_count_cf_id]}]

        options = { :body => { :issue => issue }.to_json,
                    :headers => { "Content-Type" => "application/json" } }
        ::HTTParty.send(:put, update_url({}, old_issue["issues"][0]["id"]), options)
      end
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
