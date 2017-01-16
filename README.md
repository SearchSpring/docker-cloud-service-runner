# DockerCloudServiceRunner

### What this does
1. Create a service in Docker Cloud
2. Start Service
3. Watch and output logs in real time as the service runs
4. Return the exit code from the service
5. Terminate the service

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'docker_cloud_service_runner'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install docker_cloud_service_runner

## Usage

### Running as a user
```
service = {
	:image => "debian:jessie",
	:name => "docker-cloud-runner-example",
	:run_command => "timeout 30s sh -c 'for i in `seq 1 10`; do echo $i; sleep 1; done'"
}

exit_data = DockerCloudServiceRunner::createAndRunService("username", "api-key-goes-here", service, organization)

```

### Running as an organization
```
service = {
	:image => "debian:jessie",
	:name => "docker-cloud-runner-example",
	:run_command => "timeout 30s sh -c 'for i in `seq 1 10`; do echo $i; sleep 1; done'"
}

exit_data = DockerCloudServiceRunner::createAndRunService("username", "api-key-goes-here", service, "organization")
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/searchspring/docker-cloud-service-runner. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

