require "json"
require "base64"
require "websocket-eventmachine-client"
require "rest-client"
require "thread"
require_relative "request_handler.rb"

class ServiceRunner
	# Make our instance vairables readable so that tests can see them
	attr_reader :user, :pass, :organization

	# Make our RequestHandler writable so that we can overwrite it for tests
	attr_accessor :requestHandler

	def initialize(user, pass, organization = nil)
		@requestHandler = RequestHandler.new(RestClient)
		@user = user
		@pass = pass
		@organization = organization
	end

	def authorization
		"Basic #{Base64.strict_encode64(@user + ':' + @pass)}"
	end

	def buildURI(uri)
		if(@organization != nil)
			uri = uri.sub("v1\/", "v1/#{@organization}/")
		end
		uri
	end

	def headers
		{
			'Authorization' => authorization,
			'Content-Type' => 'application/json',
			'accept' => 'application/json'
		}
	end

	def createService(service)
		data = @requestHandler.http_post(buildURI("https://cloud.docker.com/api/app/v1/service/"), service.to_json, headers)
		if(data["state"] != "Not running")
			output("Error starting container: #{data['error']}")
			exit 1
		end

		data["uuid"]
	end

	def deployService(uuid)
		data = @requestHandler.http_post(buildURI("https://cloud.docker.com/api/app/v1/service/#{uuid}/redeploy/"), {}, headers)
		state = data["state"]

		loop do
			data = @requestHandler.http_get(buildURI("https://cloud.docker.com/api/app/v1/service/#{uuid}/"), headers)
			state = data["state"]
			break if state != "Starting"
			sleep 1
		end

		state
	end

	def threadLogger(uuid)
		Thread.new do
			EM.epoll
			EM.run do

				finished = false
				Signal.trap("EXIT") { finished = true }

				ws = WebSocket::EventMachine::Client.connect(
					:uri => buildURI("wss://ws.cloud.docker.com/api/app/v1/service/#{uuid}/logs/?tail=50"),
					:headers => {"Authorization" => authorization}
				)
				ws.onopen do
					output("Connected")
				end

				ws.onmessage do |msg, type|
					msg_json = JSON.parse(msg)
					if(msg_json["log"].nil?)
						output(msg)
					else
						output(msg_json["log"].gsub(/^[\dT:.-]+Z /, ''))
					end
				end

				ws.onerror do |e|
					output("Error: #{e}")
				end

				ws.onclose do |code, reason|
					output("Disconnected with status code: #{code}")
					if(finished == false)
						output("Something went wrong with web socket for getting logs.  Disconnected with status code: #{code}. Reconnecting...")
						threadLogger(uuid)
					else
						output("Disconnected with status code: #{code}")
					end
				end

			end
		end
	end

	def output(out)
		puts out
		STDOUT.flush
	end

	def waitForStopped(uuid, state)
		loop do
			data = @requestHandler.http_get(buildURI("https://cloud.docker.com/api/app/v1/service/#{uuid}/"), headers)
			state = data["state"]
			break if state == "Stopped" || state == "Terminated"
			sleep 1
		end
		state
	end

	def terminate(uuid)
		data = @requestHandler.http_delete(buildURI("https://cloud.docker.com/api/app/v1/service/#{uuid}/"), headers)
		state = data["state"]
		if(state != "Terminated")
			loop do
				data = @requestHandler.http_get(buildURI("https://cloud.docker.com/api/app/v1/service/#{uuid}/"), headers)
				state = data["state"]
				break if state == "Terminated"
				sleep 1
			end
		end
		data["state"]
	end

	def getContainer(uuid)
		data = @requestHandler.http_get(buildURI("https://cloud.docker.com/api/app/v1/service/#{uuid}/"), headers)
		data["containers"][0].gsub(/.*container\/(.*)\//, '\1')
	end

	def quit(uuid, state)
		exit_code = 0
		exit_msg = ""
		if(state == "Stopped")

			# Get the exit code from the container
			container_uuid = getContainer(uuid)
			data = @requestHandler.http_get(buildURI("https://cloud.docker.com/api/app/v1/container/#{container_uuid}/"), headers)
			if(data["exit_code"] > 0)
				exit_code = data["exit_code"]
				exit_msg = data["exit_code_msg"]
			end

		else
			exit_code = 1
			exit_msg = "Unexpected Service State: #{state} for service #{uuid}"
		end

		{
			:exit_code => exit_code,
			:exit_msg => exit_msg
		}

	end

end