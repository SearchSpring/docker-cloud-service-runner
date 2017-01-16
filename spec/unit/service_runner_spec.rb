require "spec_helper"
require "docker_cloud_service_runner/request_handler"
require "timeout"

describe ServiceRunner do

  user="testuser"
  pass="testpass"

  describe "#initialize" do
    dockerCloudServiceRunner = ServiceRunner.new(user, pass)
    it "sets requestHandler, user, and pass" do
      expect(dockerCloudServiceRunner.user).to eql(user)
      expect(dockerCloudServiceRunner.pass).to eql(pass)
      expect(dockerCloudServiceRunner.requestHandler.class).to eql(RequestHandler)
    end
  end

  describe "#authorization" do
    dockerCloudServiceRunner = ServiceRunner.new(user, pass)
    it "returns correct Base64 encoded string for user and pass" do
      expect(dockerCloudServiceRunner.authorization()).to eql("Basic #{Base64.strict_encode64(user + ':' + pass)}")
    end
  end

  describe "#buildURI" do
    orig = "https://cloud.docker.com/api/app/v1/service/"
    it "Builds uri for a User" do
      dockerCloudServiceRunner = ServiceRunner.new(user, pass)
      expected = "https://cloud.docker.com/api/app/v1/service/"
      expect(dockerCloudServiceRunner.buildURI(orig)).to eql(expected)
    end

    it "Builds URI for a Company" do
      organization = "organizationname"
      dockerCloudServiceRunner = ServiceRunner.new(user, pass, organization)
      expected = "https://cloud.docker.com/api/app/v1/#{organization}/service/"
      expect(dockerCloudServiceRunner.buildURI(orig)).to eql(expected)
    end

  end

  describe "#headers" do
    it "returns expected headers as hash" do
      dockerCloudServiceRunner = ServiceRunner.new(user, pass)
      headers = dockerCloudServiceRunner.headers()

      expect(headers.class).to eql(Hash)
      expect(headers['Authorization']).to eql(dockerCloudServiceRunner.authorization())
      expect(headers['Content-Type']).to eql('application/json')
      expect(headers['accept']).to eql('application/json')
    end
  end

  describe "#createService" do
    dockerCloudServiceRunner = ServiceRunner.new(user, pass)
    it "Exits on any state other than 'Not running'" do
      restClient = double("one")

      expect(restClient).to receive(:post) {
        { :state => "Anything but Not running", :error => "expected error for test case" }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler

      expect do
        output = dockerCloudServiceRunner.createService({})
      end.to raise_error(SystemExit)
    end

    it "Returns a UUID for when state is 'Not running'" do
      restClient = double
      uuid = "hereistheuuid"

      expect(restClient).to receive(:post) {
        { :state => "Not running", :uuid => uuid }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      output = dockerCloudServiceRunner.createService({})

      expect(output).to eql(uuid)
    end
  end

  describe "#deployService" do
    dockerCloudServiceRunner = ServiceRunner.new(user, pass)
    it "Loops while starting" do
      restClient = double
      endState = "Running"

      expect(restClient).to receive(:post) {
        { :state => "Starting" }.to_json
      }

      expect(restClient).to receive(:get).twice {
        { :state => "Starting" }.to_json
      }

      expect(restClient).to receive(:get).once {
        { :state =>  "Running" }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      state = dockerCloudServiceRunner.deployService("hereistheuuid")

      expect(state).to eql(endState)
    end

    it "Returns state for successful deploy" do
      restClient = double
      endState = "Running"

      expect(restClient).to receive(:post) {
        { :state => "Starting" }.to_json
      }

      expect(restClient).to receive(:get) {
        { :state => endState }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      state = dockerCloudServiceRunner.deployService("hereistheuuid")

      expect(state).to eql(endState)
    end
  end

  describe "#threadLogger" do
    # Nothing.  I don't know how to test this.
  end

  describe "#waitForStopped" do
    dockerCloudServiceRunner = ServiceRunner.new(user, pass)

    it "Loops while running" do
      restClient = double
      endState = "Stopped"

      expect(restClient).to receive(:get).twice {
        { :state => "Running" }.to_json
      }

      expect(restClient).to receive(:get).once {
        { :state => endState }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      state = dockerCloudServiceRunner.waitForStopped("hereistheuuid", "Running")

      expect(state).to eql(endState)

    end

    it "Returns state for stop" do
      restClient = double
      endState = "Stopped"

      expect(restClient).to receive(:get) {
        { :state => endState }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      state = dockerCloudServiceRunner.waitForStopped("hereistheuuid", "Running")

      expect(state).to eql(endState)
    end

    it "Returns state for terminate" do
      restClient = double
      endState = "Terminated"

      expect(restClient).to receive(:get) {
        { :state => endState }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      state = dockerCloudServiceRunner.waitForStopped("hereistheuuid", "Running")

      expect(state).to eql(endState)
    end

  end

  describe "#terminate" do
    dockerCloudServiceRunner = ServiceRunner.new(user, pass)
    it "Loops while terminating" do
      restClient = double
      uuid = "hereistheuuid"
      endState = "Terminated"

      expect(restClient).to receive(:delete) {
        { :state => "Terminating" }.to_json
      }

      expect(restClient).to receive(:get).twice {
        { :state => "Terminating" }.to_json
      }

      expect(restClient).to receive(:get).once {
        { :state => endState }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      state = dockerCloudServiceRunner.terminate(uuid)

      expect(state).to eql(endState)
    end

    it "Returns state for terminate" do
      restClient = double
      uuid = "hereistheuuid"
      startState = "Terminating"
      endState = "Terminated"

      expect(restClient).to receive(:delete) {
        { :state => startState }.to_json
      }

      expect(restClient).to receive(:get) {
        { :state => endState }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      state = dockerCloudServiceRunner.terminate(uuid)

      expect(state).to eql(endState)
    end
  end

  describe "#getContainer" do
    dockerCloudServiceRunner = ServiceRunner.new(user, pass)
    it "Returns the first container" do
      restClient = double
      uuid = "hereistheuuid"
      firstContainer = "uuid1"
      containers = [
        "blah_container/" + firstContainer + "/",
        "blah_container/uuid2/",
        "blah_container/uuid3/"
      ]

      expect(restClient).to receive(:get) {
        { :containers => containers }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      containerUuid = dockerCloudServiceRunner.getContainer(uuid)

      expect(containerUuid).to eql(firstContainer)
    end
  end

  describe "#quit" do
    dockerCloudServiceRunner = ServiceRunner.new(user, pass)
    it "Returns correct exit_data for success" do
      restClient = double
      exit_code = 0
      exit_msg = ""
      containers = [
        "blah_container/uuid1/",
        "blah_container/uuid2/",
        "blah_container/uuid3/"
      ]

      expect(restClient).to receive(:get).once {
        { :containers => containers }.to_json
      }

      expect(restClient).to receive(:get).once {
        { :exit_code => exit_code, :exit_code_msg => exit_msg }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      exit_data = dockerCloudServiceRunner.quit("hereistheuuid", "Stopped")

      expect(exit_data[:exit_code]).to eql(exit_code)
      expect(exit_data[:exit_msg]).to eql(exit_msg)
    end

    it "Returns correct exit_data for failure due to bad exit code" do
      restClient = double
      exit_code = 12
      exit_msg = "bad exit msg"
      containers = [
        "blah_container/uuid1/",
        "blah_container/uuid2/",
        "blah_container/uuid3/"
      ]

      expect(restClient).to receive(:get).once {
        { :containers => containers }.to_json
      }

      expect(restClient).to receive(:get).once {
        { :exit_code => exit_code, :exit_code_msg => exit_msg }.to_json
      }

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      exit_data = dockerCloudServiceRunner.quit("hereistheuuid", "Stopped")

      expect(exit_data[:exit_code]).to eql(exit_code)
      expect(exit_data[:exit_msg]).to eql(exit_msg)
    end

    it "Returns correct exit_data for failure due to incorrect state" do
      restClient = double
      uuid = "hereistheuuid"
      state = "Terminated"
      exit_code = 1
      exit_msg = "Unexpected Service State: #{state} for service #{uuid}"

      requestHandler = RequestHandler.new(restClient)
      dockerCloudServiceRunner.requestHandler = requestHandler
      exit_data = dockerCloudServiceRunner.quit(uuid, state)

      expect(exit_data[:exit_code]).to eql(exit_code)
      expect(exit_data[:exit_msg]).to eql(exit_msg)

    end
  end

end
