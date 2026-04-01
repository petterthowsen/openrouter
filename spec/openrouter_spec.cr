require "./spec_helper"
require "./../src/openrouter"


API_KEY = begin
    File.read("./spec/api_key.txt")
rescue e
    raise "Please create a file called './spec/api_key.txt' containing your OpenRouter API key"
end

MODEL = "nvidia/llama-3.1-nemotron-70b-instruct"

describe OpenRouter do
    it "can create client", focus: false do
        client = OpenRouter::Client.new ""
        client.should be_a(OpenRouter::Client)
    end

    it "should get models as array of Model" do
        client = OpenRouter::Client.new ""

        models = client.get_models
        # models should be an array of Model structs
        models.should be_a(Array(OpenRouter::Model))
    end

    it "should serialize and deserialize JSON request", focus: false do
        request = OpenRouter::CompletionRequest.new(
            model: "mistralai/mistral-medium-3",
            tools: [
                OpenRouter::Tool.new(
                    name: "get_weather",
                    description: "Get the weather of a location",
                    parameters: [
                        OpenRouter::FunctionParameter.new(
                            name: "location",
                            type: "string",
                            description: "The location to get the weather for. For example 'tokyo' or 'new york'.",
                            required: true
                        )
                    ]
                )
            ],
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "Hi!"),
                OpenRouter::Message.new(role: OpenRouter::Role::Assistant, content: "Hi, what can I help you with?"),
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "What's the weather in Tokyo?"),
                OpenRouter::Message.new(role: OpenRouter::Role::Assistant, content: "Let me see...", tool_calls: [
                    OpenRouter::ToolCall.new(
                        id: "123456789",
                        name: "get_weather",
                        arguments: [
                            OpenRouter::ToolCallArgument.new(
                                name: "location",
                                value: "Tokyo"
                            )
                        ]
                    )
                ]),
                OpenRouter::Message.new(OpenRouter::ToolCall.new(
                    id: "123456789",
                    name: "get_weather",
                    arguments: [
                        OpenRouter::ToolCallArgument.new(
                            name: "location",
                            value: "Tokyo"
                        ),
                        OpenRouter::ToolCallArgument.new(
                            name: "temperature",
                            value: "22"
                        ),
                        OpenRouter::ToolCallArgument.new(
                            name: "unit",
                            value: "Celcius"
                        )
                    ]
                )),
            ],
        )

        request_json = request.to_json

        request_json.should be_a(String)

        deserialized = OpenRouter::CompletionRequest.from_json(request_json)
        deserialized.should be_a(OpenRouter::CompletionRequest)
    end

    it "should return response from a prompt", focus: false do
        client = OpenRouter::Client.new API_KEY
        response = client.complete("Hello, how are you?", "mistralai/mistral-7b-instruct:free")

        puts response.inspect

        response.should be_a(OpenRouter::Response)

        response.id.should be_a(String)
        response.created.should be_a(Int32)
        response.model.should be_a(String)
        response.choices.should be_a(Array(OpenRouter::Choice))
        response.usage.should be_a(OpenRouter::Usage)

        response.choices[0].should be_a(OpenRouter::Choice)

        choice = response.choices[0]
        choice.text.should be_a(String)
    end

    it "should return a message from a message completion", focus: false do
        client = OpenRouter::Client.new API_KEY

        request = OpenRouter::CompletionRequest.new(
            model: "meta-llama/llama-3.2-11b-vision-instruct:free",
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "If I have 10 apples..."),
                OpenRouter::Message.new(role: OpenRouter::Role::Assistant, content: "You have 10 apples and... ?"),
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "I eat half of them. How many do I have left?"),
            ]
        )

        puts request.to_pretty_json

        response = client.complete(request)

        response.should be_a(OpenRouter::Response)

        response.choices[0].should be_a(OpenRouter::Choice)

        choice = response.choices[0]
        message : OpenRouter::Message = choice.message.not_nil!
        message.role.should eq(OpenRouter::Role::Assistant)
        
        message.content.should be_a(String)

        message.length.should be_a(Int32)
        message.length.should be > 0
    end

    it "should call tool", focus: false do
        client = OpenRouter::Client.new API_KEY

        request = OpenRouter::CompletionRequest.new(
            model: "mistralai/mistral-large",
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "Hi. Please run the hello_world tool."),
                OpenRouter::Message.new(role: OpenRouter::Role::Assistant, content: "Hi, what can I help you with?"),
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "What's the weather in Tokyo?"),
            ],
            tools: [
                OpenRouter::Tool.new(
                    name: "get_weather",
                    description: "Get the weather of a location",
                    parameters: [
                        OpenRouter::FunctionParameter.new(
                            name: "location",
                            type: "string",
                            description: "The location to get the weather for. For example 'Tokyo' or 'New York'.",
                            required: true
                        )
                    ]
                )
            ]
        )
        
        puts "sending request:\n"
        puts request.to_pretty_json
        
        begin
            response = client.complete(request)
        rescue e
            puts e.inspect + "\n"
            next
        end

        puts "response:\n"
        puts response.to_pretty_json

        response.should be_a(OpenRouter::Response)

        response.choices[0].should be_a(OpenRouter::Choice)

        choice = response.choices[0]
        choice.message.not_nil!.role.should eq(OpenRouter::Role::Assistant)
        
        choice.message.not_nil!.tool_calls.should be_a(Array(OpenRouter::ToolCall))

        tool_calls = choice.message.not_nil!.tool_calls.not_nil!
        tool_call = tool_calls[0]
        tool_call.name.should eq("get_weather")

        tool_call.arguments.should be_a(Array(OpenRouter::ToolCallArgument))

        arguments = tool_call.arguments.not_nil!
        argument = arguments[0]
        argument.name.should eq("location")
        argument.value.should eq("Tokyo")
    end

    it "should call tool without arguments", focus: false do
        client = OpenRouter::Client.new API_KEY

        request = OpenRouter::CompletionRequest.new(
            model: "mistralai/mistral-large",
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "Hi. Please run the hello_world tool.")
            ],
            tools: [
                OpenRouter::Tool.new(
                    name: "hello_world",
                    description: "Hello world tool",
                    parameters: [] of OpenRouter::FunctionParameter
                )
            ]
        )
        
        puts "sending request:\n"
        puts request.to_pretty_json
        
        begin
            response = client.complete(request)
        rescue e
            puts e.inspect + "\n"
            next
        end

        puts "response:\n"
        puts response.to_pretty_json

        response.should be_a(OpenRouter::Response)

        response.choices[0].should be_a(OpenRouter::Choice)

        choice = response.choices[0]
        choice.message.not_nil!.role.should eq(OpenRouter::Role::Assistant)
        
        choice.message.not_nil!.tool_calls.should be_a(Array(OpenRouter::ToolCall))

        tool_calls = choice.message.not_nil!.tool_calls.not_nil!
        tool_call = tool_calls[0]
        tool_call.name.should eq("hello_world")
    end

    it "should present tool call result", focus: false do
        client = OpenRouter::Client.new API_KEY

        request = OpenRouter::CompletionRequest.new(
            model: "mistralai/mistral-medium-3",
            tools: [
                OpenRouter::Tool.new(
                    name: "get_weather",
                    description: "Get the weather of a location",
                    parameters: [
                        OpenRouter::FunctionParameter.new(
                            name: "location",
                            type: "string",
                            description: "The location to get the weather for. For example 'tokyo' or 'new york'.",
                            required: true
                        )
                    ]
                )
            ],
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "Hi!"),
                OpenRouter::Message.new(role: OpenRouter::Role::Assistant, content: "Hi, what can I help you with?"),
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "What's the weather in Tokyo?"),
                OpenRouter::Message.new(role: OpenRouter::Role::Assistant, content: "Let me see...", tool_calls: [
                    OpenRouter::ToolCall.new(
                        id: "123456789",
                        name: "get_weather",
                        arguments: [
                            OpenRouter::ToolCallArgument.new(
                                name: "location",
                                value: "Tokyo"
                            )
                        ]
                    )
                ]),
                OpenRouter::Message.new(OpenRouter::ToolCall.new(
                    id: "123456789",
                    name: "get_weather",
                    arguments: [
                        OpenRouter::ToolCallArgument.new(
                            name: "location",
                            value: "Tokyo"
                        ),
                        OpenRouter::ToolCallArgument.new(
                            name: "temperature",
                            value: "22"
                        ),
                        OpenRouter::ToolCallArgument.new(
                            name: "unit",
                            value: "Celcius"
                        )
                    ]
                )),
            ],
        )
        
        puts "sending request:\n"
        puts request.to_pretty_json
        
        begin
            response = client.complete(request)
        rescue e
            puts e.inspect + "\n"
            next
        end

        puts "response:\n"
        puts response.to_pretty_json

        response.should be_a(OpenRouter::Response)

        response.choices[0].should be_a(OpenRouter::Choice)

        choice = response.choices[0]
        choice.message.not_nil!.role.should eq(OpenRouter::Role::Assistant)
    end

    it "should describe image", focus: false do
        client = OpenRouter::Client.new API_KEY

        # load image from file and base64 encode it
        # Open the file, read its contents, and encode it to Base64
        # Open the file and read its contents
        image_path = "./spec/clock_logo.jpg"

        # Implicit close with `open` and a block:
        file = File.read image_path
        base64_image_url = "data:image/jpg;base64,#{Base64.encode file}"

        # google/gemini-flash-1.5-exp
        # meta-llama/llama-3.2-11b-vision-instruct:free

        request = OpenRouter::CompletionRequest.new(
            model: "meta-llama/llama-3.2-11b-vision-instruct:free",
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User,
                    content: [
                        OpenRouter::ContentPart.new(type: "text", value: "What's in this image?"),
                        OpenRouter::ContentPart.new(type: "image_url", value: base64_image_url),
                    ]
                ),
            ]
        )

        puts "sending request:\n"
        puts request.to_pretty_json

        begin
            response = client.complete(request)
        rescue e
            puts e.inspect + "\n"
            next
        end

        puts "response:\n"
        puts response.to_pretty_json

        response.should be_a(OpenRouter::Response)

        response.choices[0].should be_a(OpenRouter::Choice)

        choice = response.choices[0]
        choice.message.not_nil!.role.should eq(OpenRouter::Role::Assistant)

    end

    it "should support reasoning configuration", focus: false do
        client = OpenRouter::Client.new API_KEY

        request = OpenRouter::CompletionRequest.new(
            model: "z-ai/glm-4.5",
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "Solve this step by step: What is 15 * 24?"),
            ]
        )
        
        # Test different reasoning configurations
        request.reasoning = OpenRouter::Reasoning.low

        puts "sending request with reasoning:\n"
        puts request.to_pretty_json
        
        begin
            response = client.complete(request)
        rescue e
            puts "Error (expected with free models): #{e.inspect}"
            # Use a simpler test that doesn't require API call
            request.reasoning.should be_a(OpenRouter::Reasoning)
            request.reasoning.not_nil!.effort.should eq("low")
            request.reasoning.not_nil!.exclude.should eq(false)
            next
        end

        puts "response:\n"
        puts response.to_pretty_json

        response.should be_a(OpenRouter::Response)
        response.choices[0].should be_a(OpenRouter::Choice)

        choice = response.choices[0]
        choice.message.not_nil!.role.should eq(OpenRouter::Role::Assistant)
        
        # Check if reasoning was included (depends on model)
        puts "Reasoning: #{choice.message.not_nil!.reasoning}"
    end

    it "should create reasoning configurations correctly", focus: false do
        # Test high effort reasoning
        reasoning_high = OpenRouter::Reasoning.high
        reasoning_high.effort.should eq("high")
        reasoning_high.exclude.should eq(false)
        reasoning_high.max_tokens.should be_nil

        # Test medium effort reasoning
        reasoning_medium = OpenRouter::Reasoning.medium
        reasoning_medium.effort.should eq("medium")

        # Test low effort reasoning
        reasoning_low = OpenRouter::Reasoning.low
        reasoning_low.effort.should eq("low")

        # Test max tokens reasoning
        reasoning_tokens = OpenRouter::Reasoning.with_max_tokens(2000)
        reasoning_tokens.max_tokens.should eq(2000)
        reasoning_tokens.effort.should be_nil

        # Test enabled reasoning
        reasoning_enabled = OpenRouter::Reasoning.enabled
        reasoning_enabled.enabled.should eq(true)

        # Test excluded reasoning
        reasoning_excluded = OpenRouter::Reasoning.high(exclude: true)
        reasoning_excluded.effort.should eq("high")
        reasoning_excluded.exclude.should eq(true)

        # Test JSON serialization
        json_str = reasoning_high.to_json
        json_str.should contain("\"effort\":\"high\"")
        json_str.should_not contain("\"exclude\"") # false is default, shouldn't appear
    end

    it "parses response message reasoning and reasoning_details" do
        # Simulates a chat completion response with reasoning (no API call)
        response_json = <<-JSON
        {
          "id": "gen-123",
          "created": 1234567890,
          "model": "test-model",
          "choices": [
            {
              "index": 0,
              "finish_reason": "stop",
              "message": {
                "role": "assistant",
                "content": "The answer is 360.",
                "reasoning": "15 * 24 = 15 * 20 + 15 * 4 = 300 + 60 = 360",
                "reasoning_details": {"type": "reasoning", "tokens": 42}
              }
            }
          ],
          "usage": {"prompt_tokens": 10, "completion_tokens": 50, "total_tokens": 60}
        }
        JSON
        response = OpenRouter::Response.from_json(response_json)
        response.choices.size.should eq(1)
        msg = response.choices[0].message.not_nil!
        msg.role.should eq(OpenRouter::Role::Assistant)
        msg.content_string.should eq("The answer is 360.")
        msg.reasoning.should_not be_nil
        msg.reasoning.should eq("15 * 24 = 15 * 20 + 15 * 4 = 300 + 60 = 360")
        msg.reasoning_details.should_not be_nil
        msg.reasoning_details.not_nil!.as_h["type"]?.try(&.as_s).should eq("reasoning")
    end

    # --- Video input ---

    it "should serialize video_url content part correctly" do
        message = OpenRouter::Message.new(
            role: OpenRouter::Role::User,
            content: [
                OpenRouter::ContentPart.new(type: "text", value: "What's happening in this video?"),
                OpenRouter::ContentPart.new(type: "video_url", value: "https://example.com/video.mp4"),
            ]
        )

        json = JSON.parse(message.to_json)

        content = json["content"].as_a
        content.size.should eq(2)

        text_part = content[0]
        text_part["type"].as_s.should eq("text")
        text_part["text"].as_s.should eq("What's happening in this video?")

        video_part = content[1]
        video_part["type"].as_s.should eq("video_url")
        video_part["video_url"]["url"].as_s.should eq("https://example.com/video.mp4")
    end

    it "should describe video", focus: false do
        client = OpenRouter::Client.new API_KEY

        # google/gemini-2.0-flash-001 supports video input
        request = OpenRouter::CompletionRequest.new(
            model: "google/gemini-2.0-flash-001",
            messages: [
                OpenRouter::Message.new(
                    role: OpenRouter::Role::User,
                    content: [
                        OpenRouter::ContentPart.new(type: "text", value: "Describe this video in one sentence."),
                        OpenRouter::ContentPart.new(type: "video_url", value: "https://upload.wikimedia.org/wikipedia/commons/transcoded/b/b3/Big_Buck_Bunny_Trailer_400p.ogv/Big_Buck_Bunny_Trailer_400p.ogv.360p.webm"),
                    ]
                )
            ]
        )

        puts "sending request:\n"
        puts request.to_pretty_json

        begin
            response = client.complete(request)
        rescue e
            puts e.inspect + "\n"
            next
        end

        puts "response:\n"
        puts response.to_pretty_json

        response.should be_a(OpenRouter::Response)
        response.choices[0].should be_a(OpenRouter::Choice)

        choice = response.choices[0]
        choice.message.not_nil!.role.should eq(OpenRouter::Role::Assistant)
        choice.message.not_nil!.content.should be_a(String)
    end

    # --- Image generation ---

    it "should serialize modalities in completion request" do
        request = OpenRouter::CompletionRequest.new(
            model: "google/gemini-2.0-flash-exp:image",
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "Draw a red circle.")
            ]
        )
        request.modalities = ["image", "text"]

        json = JSON.parse(request.to_json)
        json["modalities"].as_a.map(&.as_s).should eq(["image", "text"])
    end

    it "should serialize image_config in completion request" do
        request = OpenRouter::CompletionRequest.new(
            model: "google/gemini-2.0-flash-exp:image",
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "Draw a red circle.")
            ]
        )
        request.modalities = ["image"]
        request.image_config = OpenRouter::ImageConfig.new(aspect_ratio: "16:9", image_size: "1K")

        json = JSON.parse(request.to_json)
        json["modalities"].as_a.map(&.as_s).should eq(["image"])
        json["image_config"]["aspect_ratio"].as_s.should eq("16:9")
        json["image_config"]["image_size"].as_s.should eq("1K")
    end

    it "should parse images from separate images field in response" do
        response_json = <<-JSON
        {
          "id": "gen-456",
          "created": 1234567890,
          "model": "google/gemini-2.0-flash-exp:image",
          "choices": [
            {
              "index": 0,
              "finish_reason": "stop",
              "message": {
                "role": "assistant",
                "content": "Here is your image.",
                "images": [{"type": "image_url", "image_url": {"url": "data:image/png;base64,iVBORw0KGgo="}}]
              }
            }
          ],
          "usage": {"prompt_tokens": 5, "completion_tokens": 10, "total_tokens": 15}
        }
        JSON

        response = OpenRouter::Response.from_json(response_json)
        msg = response.choices[0].message.not_nil!
        puts "[debug] content class: #{msg.content.class}"
        puts "[debug] content value: #{msg.content.inspect}"
        puts "[debug] images: #{msg.images.inspect}"
        puts "[debug] image_urls: #{msg.image_urls.inspect}"
        msg.role.should eq(OpenRouter::Role::Assistant)
        msg.content_string.should eq("Here is your image.")
        msg.image_urls.size.should eq(1)
        msg.image_urls[0].should eq("data:image/png;base64,iVBORw0KGgo=")
    end

    it "should parse images from content array (image_url parts) in response", focus: true do
        # This matches the actual format returned by models like flux/riverflow
        response_json = <<-JSON
        {
          "id": "gen-789",
          "created": 1234567890,
          "model": "sourceful/riverflow-v2-fast",
          "choices": [
            {
              "index": 0,
              "finish_reason": "stop",
              "message": {
                "role": "assistant",
                "content": [
                  {
                    "type": "image_url",
                    "image_url": {
                      "url": "data:image/png;base64,iVBORw0KGgo="
                    }
                  }
                ]
              }
            }
          ],
          "usage": {"prompt_tokens": 5, "completion_tokens": 10, "total_tokens": 15}
        }
        JSON

        response = OpenRouter::Response.from_json(response_json)
        msg = response.choices[0].message.not_nil!
        puts "[debug] content class: #{msg.content.class}"
        puts "[debug] content value: #{msg.content.inspect}"
        puts "[debug] multi_modal?: #{msg.multi_modal?}"
        puts "[debug] image_urls: #{msg.image_urls.inspect}"
        msg.role.should eq(OpenRouter::Role::Assistant)
        msg.multi_modal?.should be_true
        msg.image_urls.size.should eq(1)
        msg.image_urls[0].should eq("data:image/png;base64,iVBORw0KGgo=")
    end

    it "should generate image", focus: true do
        client = OpenRouter::Client.new API_KEY

        request = OpenRouter::CompletionRequest.new(
            model: "sourceful/riverflow-v2-fast",
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "Generate a simple image of a red circle on a white background.")
            ]
        )
        request.modalities = ["image"]

        puts "sending request:\n"
        puts request.to_pretty_json

        begin
            response = client.complete(request)
        rescue e
            puts e.inspect + "\n"
            next
        end

        # Print raw response JSON with long base64 values trimmed for readability
        raw_json = response.to_json.gsub(/([A-Za-z0-9+\/]{60})[A-Za-z0-9+\/=]+/, "\\1...[truncated]")
        puts "response (base64 trimmed):\n"
        puts JSON.parse(raw_json).to_pretty_json

        response.should be_a(OpenRouter::Response)
        response.choices[0].should be_a(OpenRouter::Choice)

        msg = response.choices[0].message.not_nil!
        puts "[debug] content class: #{msg.content.class}"
        puts "[debug] content value: #{msg.content.inspect}"
        puts "[debug] multi_modal?: #{msg.multi_modal?}"
        puts "[debug] images field: #{msg.images.inspect}"
        puts "[debug] image_urls: #{msg.image_urls.inspect}"
        msg.role.should eq(OpenRouter::Role::Assistant)
        msg.image_urls.size.should be > 0
    end

    it "can fake tools for", focus: false do
        client = OpenRouter::Client.new API_KEY

        request = OpenRouter::CompletionRequest.new(
            model: "qwen/qwen-2.5-72b-instruct",
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "Hi. Please run the hello_world tool."),
            ],
            tools: [
                OpenRouter::Tool.new(
                    name: "hello_world",
                    description: "Prints a test message",
                    parameters: [
                        OpenRouter::FunctionParameter.new(
                            name: "message",
                            type: "string",
                            description: "The message to print.",
                            required: true
                        )
                    ]
                )
            ]
        )
        request.force_tool_support = true
        request.respond_with_json = true
        
        puts "sending request:\n"
        puts request.to_pretty_json
        
        response = client.complete(request)

        puts "response:\n"
        puts response.to_pretty_json

        response.should be_a(OpenRouter::Response)

        response.choices[0].should be_a(OpenRouter::Choice)

        choice = response.choices[0]
        choice.message.not_nil!.role.should eq(OpenRouter::Role::Assistant)

        choice.message.not_nil!.tool_calls.should be_a(Array(OpenRouter::ToolCall))

        tool_calls = choice.message.not_nil!.tool_calls.not_nil!
        tool_calls.should be_a(Array(OpenRouter::ToolCall))

        tool_call = tool_calls[0]
        tool_call.name.should eq("hello_world")
    end
end
