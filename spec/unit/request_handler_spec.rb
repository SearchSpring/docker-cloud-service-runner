require "docker_cloud_service_runner/request_handler"

describe RequestHandler do

	describe "http_get" do
		it "parses a JSON GET response correctly" do
			restClient = double
			expect(restClient).to receive(:get) { '{"ret": "output"}' }
			requestHandler = RequestHandler.new(restClient)
			expect(requestHandler.http_get("uir", { headers: "" })['ret']).to eq("output")
		end
	end

	describe "http_post" do
		it "parses a JSON POST response correctly" do
			restClient = double
			expect(restClient).to receive(:post) { '{"ret": "output"}' }
			requestHandler = RequestHandler.new(restClient)
			expect(requestHandler.http_post("uri", "service", { headers: "" })['ret']).to eq("output")
		end
	end

	describe "http_delete" do
		it "parses a JSON DELETE response correctly" do
			restClient = double
			expect(restClient).to receive(:delete) { '{"ret": "output"}' }
			requestHandler = RequestHandler.new(restClient)
			expect(requestHandler.http_delete("uri", { headers: "" })['ret']).to eq("output")
		end
	end
end