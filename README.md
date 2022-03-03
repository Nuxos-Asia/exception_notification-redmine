# ExceptionNotification::Redmine

This gem add a Redmine notifier to Exception Notification.

This Ruby gem is an extension of the [exception_notification gem](http://rubygems.org/gems/exception_notification) to support creating issues in Redmine.

## Fork notice.
This fork exists as a updated version of the [http://rubygems.org/gems/exception_notification-redmine](http://rubygems.org/gems/exception_notification-redmine) gem.
I have attempted to contact the original developer to add these changes however this has been unsuccessful.
The devs have been inactive for a few years and the companies website is now dead so assuming the original maintainers are no longer actively maintaining this gem

As this is a gem I use I am looking at taking over development. At present there is no build on rubygems. You will need to install directly from this fork. Installation instructions have been updated to this end.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'exception_notification-redmine', :git => 'https://github.com/geocom/exception_notification-redmine.git'
```

And then execute:

    $ bundle

Or install it yourself as:
    $ git clone https://github.com/geocom/exception_notification-redmine.git
    $ cd exception_notification-redmine
    $ rake gem
    $ gem install pkg/exception_notification-redmine-<version>.gem

## Usage

**IMPORTANT:** You must create a custom field named `x_checksum` in your Redmine project for the Redmine notifier to work properly

**IMPORTANT FOR OPTIONAL SETTING:** To enable the hit counter you must add `x_hit_count` in your Redmine project so existing issues can be updated with an occurrence number

**IMPORTANT FOR OPTIONAL SETTING:** You must add a wontfix status in redmine to enable reopening of closed issues.

As of Rails 3 ExceptionNotification-Redmine is used as a rack middleware, or in the environment you want it to run. In most cases you would want ExceptionNotification-Redmine to run on production. Thus, you can make it work by putting the following lines in your `/config/initializers` folder you can also add this to `config/environments/production.rb` however rails wipes this file when updating along with the fact that if you use git you risk adding your credentials or removing production.rb from the repo.:

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
  # fixed_version_id: create issues with the given fixed_version_id (aka target version id)
  # x_checksum_cf_id: custom field used to avoid creation of the same issue multiple times. You must use the DOM id assigned by Redmine to this field in the issue form. You can find it by creating an issue manually in your project and inspecting the HTML form, you should see something like name="issue[custom_field_values][19]", in this case the id would be 19. Make sure you set the custom field to be used as a filter
  # formatting: Redmine offers Markdown or Textile. Optional value. Will default to Markdown if anything else is entered other than textile. You will need to set this based on what you have in Redmine Administration -> Settings -> Text formatting


  :redmine => {
    :host_url => "https://redmine.example.com",
    :issues_url => "issues", #Note Depreciation warning for updating code. Old versions included the format within the issues url. However in order to update issues the format needs to proceed the ticket number. For now the old formatting will continue to work provided that you have not added x_hit_count_cf_id to your config. Please update to include request_format as this fallback may be removed in a future revision of this gem to save on code size.
    :request_format => "json",
    :issues_prefix => "[Error]",
    :api_key => "123456",
    :project_id => "test-project",
    :tracker_id => "1", # Bug
    :assigned_to_id => "123",
    :priority_id => "6", # Urgent
    :status_id => "1", # New
    :fixed_version_id => "1", # id of the issue target version on redmine
    :x_checksum_cf_id => "19", # DOM id in Redmine issue form
    :formatting => "textile", #Optional defaults to Markdown if left out or any other type is input.
    :x_hit_count_cf_id =>"20", #Optional if issue already exits it will update that issue with more information. If nil it will not update the custom field hit counter. DOM id in Redmine issue form
    :add_note_on_update  => true, #Optional if issue already exits it will update that issue and add a note to the issue with the description. Requires x_hit_count_cf_id to be set first
    :reopen_issue_if_closed => [1, [3, 5, 6], 8] #Optional, will reopen issue if closed. to setup put the id values for your statuses [reopen to, [array of closed statuses. if any of these the issue will be reopened], wontfix]
  }
```
## Contributing

1. Fork it ( https://github.com/geocom/exception_notification-redmine/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
