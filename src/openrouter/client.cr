# src/openrouter/client.cr
require "http/client"
require "http/headers"
require "json"

module OpenRouter

  # Client for the OpenRouter API
  class Client
    BASE_URL = "https://openrouter.ai/api/v1"

    property api_key : String

    # It tells OpenRouter which app is using the API
    # see #app_url
    property app_name : String?

    # Together with #app_name it tells OpenRouter which app is using the API
    property app_url : String?

    # Initialize a new OpenRouter::Client
    # 
    # The *api_key* is generally required to use the API (though an invalid key seems to allow querying for models.)
    # *app_name* and *app_url* are optional and tell OpenRouter about your application.
    def initialize(api_key : String, app_name : String? = nil, app_url : String? = nil)
      @api_key = api_key
      @app_name = app_name
      @app_url = app_url
    end

    # Returns an array of Model structs representing the available models currently supported by OpenRouter
    def get_models : Array(Model)
      models_json = get("/models")

      # Extract the "data" key and ensure it's an array
      data = models_json["data"] || raise "Invalid response: 'data' key missing"
      data_array = data.as_a || raise "Invalid response: 'data' is not an array"

      # Map the array to Model structs
      data_array.map { |model_json| OpenRouter::Model.new(model_json) }
    end

    # Send a completion request for a text prompt using the specified model
    def complete(prompt : String, model : String) : Response
      completion_request = CompletionRequest.new(prompt, model)
      response_json = post("/chat/completions", completion_request.to_json)
      Response.new(response_json)
    end

    # Send a completion request using the specified CompletionRequest object
    def complete(request : CompletionRequest) : Response
      response_json = post("/chat/completions", request.to_json)
      Response.new(response_json)
    end

    # Get a specific endpoint
    # 
    # This is a low-level method that is available for edge cases.
    def get(endpoint : String) : JSON::Any
      request("GET", endpoint)
    end

    # Post to a specific endpoint
    # 
    # This is a low-level method that is available for edge cases.
    def post(endpoint : String, body : String?) : JSON::Any
      request("POST", endpoint, body)
    end

    # Send a request to the OpenRouter API on a given http verb + endpoint with an optional body
    private def request(method : String, endpoint : String, body : String? = nil) : JSON::Any
      method = method.upcase

      # build the headers
      headers = HTTP::Headers.new
      headers["Authorization"] = "Bearer #{@api_key}"
      headers["Content-Type"] = "application/json"

      # Add optional headers
      if @app_name != nil
        headers["X-Title"] = @app_name.to_s
      end

      if @app_url != nil
        headers["HTTP-Referrer"] = @app_url.to_s
      end

      url = "#{BASE_URL}#{endpoint}"

      # if body
      #   puts "Sending #{method} request to #{url} with body:"
      #   puts body
      # end

      begin
        response = HTTP::Client.exec method, url, headers: headers, body: body
      rescue e
        raise OpenRouter::Error.new("Network or client error: #{e.message}")
      end

      handle_response(response)
    end

    private def handle_response(response : HTTP::Client::Response) : JSON::Any
      if response.status.success?
        # Even with 200 OK, check if the body contains an error object
        parsed = JSON.parse(response.body)

        if parsed.is_a?(Hash) && parsed["error"]
          handle_api_error(parsed["error"].as_h)
        else
          parsed
        end
      else
        # Handle HTTP status codes that indicate errors
        handle_http_error(response.status_code, response.body)
      end
    end

    private def handle_http_error(status_code : Int32, body : String) : JSON::Any
      error_message = "HTTP Error #{status_code}: #{body}"
      case status_code
      when 400
        raise BadRequestError.new(error_message)
      when 401
        raise UnauthorizedError.new(error_message)
      when 402
        raise PaymentRequiredError.new(error_message)
      when 403
        raise ForbiddenError.new(error_message)
      when 408
        raise RequestTimeoutError.new(error_message)
      when 429
        raise TooManyRequestsError.new(error_message)
      when 502
        raise BadGatewayError.new(error_message)
      when 503
        raise ServiceUnavailableError.new(error_message)
      else
        raise ApiError.new(error_message)
      end
    end

    private def handle_api_error(error_obj : Hash(String, JSON::Any)) : JSON::Any
      code = error_obj["code"].as_i32?
      message = error_obj["message"].as_s || "Unknown API error"
      metadata = error_obj["metadata"]

      error_message = "API Error #{code}: #{message}"
      error_message += " | Metadata: #{metadata}" if metadata

      case code
      when 400
        raise BadRequestError.new(error_message)
      when 401
        raise UnauthorizedError.new(error_message)
      when 402
        raise PaymentRequiredError.new(error_message)
      when 403
        raise ForbiddenError.new(error_message)
      when 408
        raise RequestTimeoutError.new(error_message)
      when 429
        raise TooManyRequestsError.new(error_message)
      when 502
        raise BadGatewayError.new(error_message)
      when 503
        raise ServiceUnavailableError.new(error_message)
      else
        raise ApiError.new(error_message)
      end
    end
  end
end
