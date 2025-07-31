require "uuid"

module OpenRouter

    class InvalidJSONResponse < Exception
        getter text : String
        getter cause : Exception?

        def initialize(text : String, cause : Exception? = nil)
            super("Invalid JSON: #{text}")
            @text = text
            @cause = cause
        end
    end

    enum ResponseObject
        ChatCompletion
        ChatCompletionChunk
    end

    struct Usage
        getter prompt : Int32
        getter completion : Int32
        getter total : Int32

        def initialize(json : JSON::Any)
            @prompt = json["prompt_tokens"].as_i
            @completion = json["completion_tokens"].as_i
            @total = json["total_tokens"].as_i
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
              to_json(json) # Delegate to the JSON::Builder version
            end
        end

        def to_json(json : JSON::Builder)
            json.object do
                json.field "prompt", @prompt
                json.field "completion", @completion
                json.field "total", @total
            end
        end
    end

    abstract struct Choice
        getter finish_reason : String?
        abstract def initialize(json : JSON::Any)
        abstract def to_json(io : IO)
        abstract def to_json(json : JSON::Builder)
    end

    struct NonChatChoice < Choice
        getter text : String

        def initialize(json : JSON::Any)
            @text = json["text"].as_s
            @finish_reason = json.as_h.has_key?("finish_reason") ? json["finish_reason"].as_s? : nil
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
              to_json(json) # Delegate to the JSON::Builder version
            end
        end

        def to_json(json : JSON::Builder)
            json.object do
                json.field "text", @text
                json.field "finish_reason", @finish_reason if @finish_reason
            end
        end
    end

    # Represents a non-streaming response
    struct NonStreamingChoice < Choice
        property message : Message

        def initialize(json : JSON::Any)
            @message = Message.from_json(json["message"])
            @finish_reason = json.as_h.has_key?("finish_reason") ? json["finish_reason"].as_s? : nil
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
              to_json(json) # Delegate to the JSON::Builder version
            end
        end

        def to_json(json : JSON::Builder)
            json.object do
                json.field "message", @message
                json.field "finish_reason", @finish_reason if @finish_reason
            end
        end
    end

    # Represents a streaming response
    # 
    # The delta property contains a partial message.
    struct StreamingChoice < Choice
        getter delta : Message

        def initialize(json : JSON::Any)
            @delta = Message.from_json(json["delta"])
            @finish_reason = json.as_h.has_key?("finish_reason") ? json["finish_reason"].as_s? : nil
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
              to_json(json) # Delegate to the JSON::Builder version
            end
        end

        def to_json(json : JSON::Builder)
            json.object do
                json.field "delta", @delta
                json.field "finish_reason", @finish_reason if @finish_reason
            end
        end
    end

    # Represents a response from 
    struct Response
        getter id : String?
        getter created : Int32
        getter model : String

        getter choices : Array(Choice) = [] of Choice

        # Usage data is always returned for non-streaming.
        # When streaming, you will get one usage object at
        # the end accompanied by an empty choices array.
        getter usage : Usage?

        def to_json(io : IO)
            JSON.build(io) do |json|
              to_json(json) # Delegate to the JSON::Builder version
            end
        end

        def to_json(json : JSON::Builder)
            json.object do
                json.field "id", @id
                json.field "created", @created
                json.field "model", @model
                json.field "choices", @choices
                json.field "usage", @usage if @usage
            end
        end

        def self.from_request(request : CompletionRequest, response_json : JSON::Any)
            response = new(response_json)

            if request.respond_with_json
                puts "Parsing response message as JSON..."

                # verify json
                message = response.choices[0].as(NonStreamingChoice).message
                text = message.content_string

                puts "raw text: #{text}"

                # remove any text before the json
                text = text.gsub /^[^\{]+/, ""

                # remove any text after the json
                text = text.gsub /[^\}]+$/, ""

                puts "cleaned up: `#{text}`"

                begin
                    # parse json and see if there's any tool calls
                    json = JSON.parse(text)
                rescue e
                    raise InvalidJSONResponse.new("Invalid JSON in message content: #{text}", e)
                end

                if request.force_tool_support
                    puts "force tool support..."

                    if json["message"]?
                        message.content = json["message"].as_s
                    else
                        message.content = ""
                    end

                    puts "message content set: #{message.content}"

                    # parse tool calls
                    if json["tool_calls"]?
                        puts "parsing tool calls..."

                        message.tool_calls = json["tool_calls"].as_a.map do |tool_call_json|
                            if tool_call_json["function"]?
                                func = tool_call_json["function"].as_h
                            else
                                func = tool_call_json
                            end

                            # function name
                            if func["name"]?
                                name = func["name"].as_s
                            else
                                raise InvalidJSONResponse.new("Missing function name in tool call.")
                            end

                            puts "function name: #{name}"

                            # function arguments, it could be a JSON string or a JSON object
                            if func["arguments"]?
                                puts "arguments : #{func["arguments"].to_s}"

                                if func["arguments"].as_s?
                                    puts "arguments is a JSON string, parsing..."
                                    begin
                                        args = JSON.parse(func["arguments"].as_s).as_h
                                    rescue e
                                        raise InvalidJSONResponse.new("Invalid JSON in tool call arguments.", e)
                                    end
                                else
                                    args = func["arguments"].as_h? || {} of String => JSON::Any
                                end
                            else
                                args = {} of String => JSON::Any
                            end

                            # create arguments array as an array of ToolCallArgument
                            arguments = args.map do |key, value|
                                ToolCallArgument.new(key, value)
                            end

                            # generate a unique id
                            id = "tool_call_" + UUID.random.to_s

                            ToolCall.new(id, name, arguments, "function")
                        end

                    end

                    choice = response.choices[0].as(NonStreamingChoice)
                    choice.message = message
                    response.choices[0] = choice
                end
            end

            response
        end

        def initialize(json : JSON::Any)
            @id = json["id"]? ? json["id"].as_s : nil
            @created = json["created"].as_i
            @model = json["model"].as_s
            
            # loop through choices
            # and add them to the choices array
            json["choices"].as_a.each do |choice_json|
                if choice_json.as_h.has_key? "text"
                    @choices << NonChatChoice.new(choice_json)
                elsif choice_json.as_h.has_key? "message"
                    @choices << NonStreamingChoice.new(choice_json)
                elsif choice_json.as_h.has_key? "delta"
                    @choices << StreamingChoice.new(choice_json)
                else
                    raise "Unknown choice type in choice #{choice_json}"
                end
            end

            if json.as_h.has_key? "usage"
                @usage = Usage.new(json["usage"])
            end
        end
    end
end