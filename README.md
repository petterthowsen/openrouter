# openrouter

HTTP Client for the OpenRouter API (https://openrouter.ai)

## Support / Features

- text completion
- chat completion
- multimodal I.E images
- tool use


## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     openrouter:
       github: petterthowsen/openrouter
   ```

2. Run `shards install`

## Usage

```crystal
require "openrouter"

# create a client instance
client = OpenRouter::Client.new "sk-or-v1-123456789..."

# get available models as an Array of OpenRouter::Model 
models = client.get_models

# get a completion from a single text prompt:
response = client.complete("Hello, how are you?", "mistralai/mistral-7b-instruct:free")

# or use the CompletionRequest class to construct a more complex request with multiple messages:
request = OpenRouter::CompletionRequest.new(
  model: "mistralai/mistral-7b-instruct:free",
  messages: [
    OpenRouter::Message.new(role: OpenRouter::Role::User, content: "If I have 10 apples..."),
    OpenRouter::Message.new(role: OpenRouter::Role::Assistant, content: "You have 10 apples and... ?"),
    OpenRouter::Message.new(role: OpenRouter::Role::User, content: "I eat half of them. How many do I have left?"),
  ]
)

response = client.complete(request)

# you can get the content like this:
choice = response.choices[0].as(OpenRouter::NonStreamingChoice)

# choice is a OpenRouter::Content
# which is alias of String | Array(NamedTuple(type, value))
# if you know it's only one text response, use the utility method:
text : String = choice.content_string
puts "AI Responded with: " + text

# otherwise, you can access it like so (I think):
choice.content[0][:value] # => String

```

## Development

The main class is the Client in `./src/openrouter/client.cr`.

It uses the CompletionRequest in `./src/openrouter/types/completion_request.cr` and Response in `./src/openrouter/types/response.cr`.

## Contributing

1. Fork it (<https://github.com/petterthowsen/openrouter/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Petter Thowsen](https://github.com/petterthowsen) - creator and maintainer
