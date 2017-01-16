require "docker_cloud_service_runner/version"
require "docker_cloud_service_runner/service_runner"
require "docker_cloud_service_runner/request_handler"

module DockerCloudServiceRunner
  def self.createAndRunService(username, apikey, service, organization = nil)

    serviceRunner = ServiceRunner.new(username, apikey, organization)

    # Create service
    uuid = serviceRunner.createService(service)
    serviceRunner.output("Service Created: #{uuid}")

    exit_data = {}

    begin
      # Deploy service
      state = serviceRunner.deployService(uuid)
      if(state == "Running")
        serviceRunner.output("Service Deployed: #{uuid}")
      end

      # Secondary thread to output logs using web socket
      thr = serviceRunner.threadLogger(uuid)

      # Loop until Stopped
      state = serviceRunner.waitForStopped(uuid, state)

      # Check state, terminate if success, exit with code
      exit_data = serviceRunner.quit(uuid, state)
    rescue Exception => e
      exit_data = {
        :exit_code => 1,
        :exit_msg => "Exception thrown: " + e.message
      }
    ensure
      state = serviceRunner.terminate(uuid)
      serviceRunner.output("Service Terminated: #{uuid}")
    end

    if(exit_data[:exit_code] > 0)
      serviceRunner.output("Bad exit [#{exit_data[:exit_code]}]: #{exit_data[:exit_msg]}")
    end

    exit_data

  end
end
