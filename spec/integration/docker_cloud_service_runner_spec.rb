require "spec_helper"

describe DockerCloudServiceRunner do
  it "successfully runs a service as a user" do
    username = ENV["DOCKER_CLOUD_SERVICE_RUNNER_USERNAME"]
    apikey = ENV["DOCKER_CLOUD_SERVICE_RUNNER_APIKEY"]
    service = {
      :image => "debian:jessie",
      :name => "dc-runner-test-user",
      :run_command => "timeout 30s sh -c 'for i in `seq 1 3`; do echo $i; sleep 1; done'"
    }

    exit_data = DockerCloudServiceRunner::createAndRunService(username, apikey, service)
    expect(exit_data[:exit_code]).to eq(0)
  end

  it "successfully runs a service as an organization" do
    username = ENV["DOCKER_CLOUD_SERVICE_RUNNER_USERNAME"] || "username"
    apikey = ENV["DOCKER_CLOUD_SERVICE_RUNNER_APIKEY"] || "apikey"
    organization = ENV["DOCKER_CLOUD_SERVICE_RUNNER_ORGANIZATION"] || "organization"
    service = {
      :image => "debian:jessie",
      :name => "dc-runner-test-org",
      :run_command => "timeout 30s sh -c 'for i in `seq 1 3`; do echo $i; sleep 1; done'"
    }

    exit_data = DockerCloudServiceRunner::createAndRunService(username, apikey, service, organization)
    expect(exit_data[:exit_code]).to eq(0)
  end
end
