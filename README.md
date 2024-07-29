# Rack::Webfinger

A very basic first pass at a Rack middleware to serve up Webfinger
requests. There isn't much to serving up Webfinger requests, so this
middleware won't do much.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add rack-webfinger

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install rack-webfinger

## Usage

In your `config.ru` add:

```ruby
    require 'rack/webfinger'

    use Rack::Webfinger, provider
```

`provider` must be a callable (lambda, proc, class responding to `#
call`) that takes a resource name and an array of rel filters in.
You can choose to ignore the rel filters - filtering will be done for
you.

You need to return a Hash of this format:

```
    {
      aliases: ["list","of","aliases"],
      links: [
        { "rel": "rel url", "type": "text/html", "href": "link" }
      ]
    }
```

This will be simplified, with constants for common rel values, and
defaults available.


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vidarh/rack-webfinger.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
