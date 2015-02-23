# Rssendy

Hook into an RSS feed and import the results into your [sendy](http://sendy.co) installation.

## Installation

`rssendy` can be used either as a command line application or a library in your application.

Add this line to your application's Gemfile:

```ruby
gem 'rssendy'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rssendy

## Usage

Either define a configuration file for your feed or use the CLI options. The options are as follows:

| Option        | Description                                                                             | Required? |
| ------        | -----------                                                                             | --------- |
| config        | Path to YAML config file                                                                | *no*      |
| api_key       | Sendy API key                                                                           | *yes*     |
| url           | URL of sendy app                                                                        | *yes*     |
| content       | Nokogiri parser for RSS items. This will be `eval`'d in the context of your parsed feed | *yes*     |
| path          | Path to your feeds template file                                                        | *yes*     |
| from-name     | The name in the 'From' field                                                            | *yes*     |
| from-email    | The address in the 'From' field                                                         | *yes*     |
| reply-to      | The address in the 'Reply-To' field                                                     | *yes*     |
| subject       | The email 'Subject' field                                                               | *yes*     |
| plain-text    | The plain text version of your email                                                    | *no*      |
| list-ids      | Comma separated list of sendy list ids                                                  | *no*      |
| brand-id      | Sendy Brand ID                                                                          | *no*      |
| send-campaign | Send the email or not (sendy default is 0)                                              | *no*      |


When using a YAML config file replace `-` (dash) with `_` (underscore). Options listed in the config file may be overridden by the command line options.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rssendy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
