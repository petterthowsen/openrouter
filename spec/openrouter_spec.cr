require "./spec_helper"
require "./../src/openrouter"

API_KEY = ""

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
end
