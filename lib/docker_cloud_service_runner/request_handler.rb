require "json"

class RequestHandler
	def initialize(restClient)
		@restClient = restClient
	end

	def http_get(uri, headers)
		retries = 5
		begin
			response = @restClient.get(uri, headers)
			JSON.parse(response)
		rescue Exception => e
			if (retries -= 1) > 0
				puts "Exception: #{e.message}.  Will try again up to #{retries} times"
				sleep 10
				retry
			else
				throw e
			end
		end
	end

	def http_post(uri, service, headers)
		retries = 5
		begin
			response = @restClient.post(uri, service, headers)
			JSON.parse(response)
		rescue Exception => e
			if (retries -= 1) > 0
				puts "Exception: #{e.message}.  Will try again up to #{retries} times"
				sleep 10
				retry
			else
				throw e
			end
		end
	end

	def http_delete(uri, headers)
		retries = 5
		begin
			response = @restClient.delete(uri, headers)
			JSON.parse(response)
		rescue Exception => e
			if (retries -= 1) > 0
				puts "Exception: #{e.message}.  Will try again up to #{retries} times"
				sleep 10
				retry
			else
				throw e
			end
		end
	end
end