# ExceptionNotification::Redmine

This gem add a Redmine notifier to Exception Notification.

This Ruby gem is an extension of the [exception_notification gem](http://rubygems.org/gems/exception_notification) to support creating issues in Redmine.

[![Gem Version](https://badge.fury.io/rb/exception_notification-redmine.svg)](http://badge.fury.io/rb/exception_notification-redmine)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'exception_notification-redmine'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install exception_notification-redmine

## Usage

**IMPORTANT:** You must create a custom field named `x_checksum` in your Redmine project for the Redmine notifier to work properly

As of Rails 3 ExceptionNotification-Redmine is used as a rack middleware, or in the environment you want it to run. In most cases you would want ExceptionNotification-Redmine to run on production. Thus, you can make it work by putting the following lines in your `config/environments/production.rb`:

```ruby
Whatever::Application.config.middleware.use ExceptionNotification::Rack,
  # host_url: url of your Redmine host
  # issues_url: issues.json (Redmine REST API)
  # issues_prefix: text prepended to the issue title (default: "[Error]")
  # api_key: the api key of the user that will be used to create the Redmine issue
  # project_id: create issues in the project with the given id, where id is either project_id or project identifier
  # tracker_id: create issues with the given tracker_id
  # assigned_to_id: create issues which are assigned to the given user_id
  # priority_id: create issues with the given priority_id
  # status_id: create issues with the given status_id
  # x_checksum_cf_id: custom field used to avoid creation of the same issue multiple times. You must use the DOM id assigned by Redmine to this field in the issue form. You can find it by creating an issue manually in your project and inspecting the HTML form, you should see something like name="issue[custom_field_values][19]", in this case the id would be 19.
  
  :redmine => {
    :host_url => "https://redmine.example.com",
    :issues_url => "issues.json",
    :issues_prefix => "[Error]",
    :api_key => "123456",
    :project_id => "test-project",
    :tracker_id => "1", # Bug
    :assigned_to_id => "123",
    :priority_id => "6", # Urgent
    :status_id => "1", # New
    :x_checksum_cf_id => "19" # DOM id in Redmine issue form
  }
```
## Contributing

1. Fork it ( https://github.com/Nuxos-Asia/exception_notification-redmine/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
