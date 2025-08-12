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
        include JSON::Serializable

        @[JSON::Field(key: "prompt_tokens")]
        getter prompt : Int32
        
        @[JSON::Field(key: "completion_tokens")]
        getter completion : Int32
        
        @[JSON::Field(key: "total_tokens")]
        getter total : Int32

        def initialize(@prompt : Int32, @completion : Int32, @total : Int32)
        end
    end

    struct Choice
        include JSON::Serializable

        getter finish_reason : String?
        
        # For non-chat completions (text generation)
        getter text : String?
        
        # For chat completions (non-streaming)
        property message : Message?
        
        # For streaming completions
        getter delta : Message?
    end

    # Represents a response from 
    struct Response
        include JSON::Serializable

        getter id : String?
        getter created : Int32
        getter model : String

        getter choices : Array(Choice) = [] of Choice

        # Usage data is always returned for non-streaming.
        # When streaming, you will get one usage object at
        # the end accompanied by an empty choices array.
        getter usage : Usage?

        def self.from_request(request : CompletionRequest, response_json : JSON::Any)
            response = from_json(response_json.to_json)

            if request.respond_with_json
                puts "Parsing response message as JSON..."

                # verify json
                message = response.choices[0].message.not_nil!
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

                    choice = response.choices[0]
                    choice.message = message
                    response.choices[0] = choice
                end
            end

            response
        end


    end
end