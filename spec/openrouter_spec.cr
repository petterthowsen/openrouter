require "./spec_helper"
require "./../src/openrouter"


API_KEY = begin
    File.read("./spec/api_key.txt")
rescue e
    raise "Please create a file called './spec/api_key.txt' containing your OpenRouter API key"
end

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

        response.choices[0].should be_a(OpenRouter::NonChatChoice)

        choice = response.choices[0].as(OpenRouter::NonChatChoice)
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

        response.choices[0].should be_a(OpenRouter::NonStreamingChoice)

        choice = response.choices[0].as(OpenRouter::NonStreamingChoice)
        message : OpenRouter::Message = choice.message
        message.role.should eq(OpenRouter::Role::Assistant)
        
        message.content.should be_a(String)
    end

    it "should call tool", focus: false do
        client = OpenRouter::Client.new API_KEY

        request = OpenRouter::CompletionRequest.new(
            model: "cohere/command-r-08-2024",
            messages: [
                OpenRouter::Message.new(role: OpenRouter::Role::User, content: "Hi!"),
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
                            description: "The location to get the weather for. For example 'tokyo' or 'new york'.",
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

        response.choices[0].should be_a(OpenRouter::NonStreamingChoice)

        choice = response.choices[0].as(OpenRouter::NonStreamingChoice)
        choice.message.role.should eq(OpenRouter::Role::Assistant)
        
        choice.message.tool_calls.should be_a(Array(OpenRouter::ToolCall))

        tool_calls = choice.message.tool_calls.not_nil!
        tool_call = tool_calls[0]
        tool_call.name.should eq("get_weather")

        tool_call.arguments.should be_a(Array(OpenRouter::ToolCallArgument))

        arguments = tool_call.arguments.not_nil!
        argument = arguments[0]
        argument.name.should eq("location")
        argument.value.should eq("Tokyo")
    end

    it "should present tool call result", focus: false do
        client = OpenRouter::Client.new API_KEY

        request = OpenRouter::CompletionRequest.new(
            model: "cohere/command-r-08-2024",
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
                        id: "get_weather_9pw1qnYScqvGrCH58HWCvFH6",
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
                    id: "get_weather_9pw1qnYScqvGrCH58HWCvFH6",
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

        response.choices[0].should be_a(OpenRouter::NonStreamingChoice)

        choice = response.choices[0].as(OpenRouter::NonStreamingChoice)
        choice.message.role.should eq(OpenRouter::Role::Assistant)
    end

    it "should describe image", focus: true do
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

        response.choices[0].should be_a(OpenRouter::NonStreamingChoice)

        choice = response.choices[0].as(OpenRouter::NonStreamingChoice)
        choice.message.role.should eq(OpenRouter::Role::Assistant)

    end
end
