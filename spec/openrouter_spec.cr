require "./spec_helper"
require "./../src/openrouter"

API_KEY = "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"

describe OpenRouter do
    it "can create client" do
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
        choice.message.role.should eq(OpenRouter::Role::Assistant)

        puts choice.message.content
    end

    it "should call tool", focus: true do
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
    end
end
