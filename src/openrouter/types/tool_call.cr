module OpenRouter

    struct ToolCallArgument
        getter name : String
        getter value : JSON::Any

        def initialize(name : String, value : JSON::Any)
            @name = name
            @value = value
        end

        def initialize(name : String, value : String)
            @name = name
            @value = JSON::Any.new(value)
        end

        def self.from_json(json : JSON::Any)
            name = json["name"].as_s
            value = json["value"]
            ToolCallArgument.new(name, value)
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
              to_json(json) # Delegate to the JSON::Builder version
            end
        end

        def to_json(json : JSON::Builder)
            json.object do
                json.field "name", @name
                json.field "value", @value.raw
            end
        end
    end

     # tool calls look like this:
    # "tool_calls": [
    #     {
    #       "id": "call_9pw1qnYScqvGrCH58HWCvFH6",
    #       "type": "function",
    #       "function": {
    #         "name": "get_current_weather",
    #         "arguments": "{ \"location\": \"Boston, MA\"}"
    #       }
    #     }
    #   ]
    struct ToolCall
        getter id : String
        getter type : String = "function"
        getter name : String
        getter arguments : Array(ToolCallArgument) = [] of ToolCallArgument

        def initialize(
            @id : String,
            @name : String,
            @arguments : Array(ToolCallArgument)    = [] of ToolCallArgument,
            @type : String = "function"
        )
        end

        def self.from_json(json : String)
            ToolCall.new(JSON.parse(json))
        end

        def self.from_json(json : JSON::Any)
            ToolCall.new(json)
        end
       
        def initialize(json : JSON::Any)
            @id = json["id"].as_s
            @type = json["type"].as_s
            @name = json["function"]["name"].as_s
        
            # Handle `arguments`
            raw_arguments = json["function"]["arguments"]

            if raw_arguments.try &.as_s?
                arguments_string = raw_arguments.as_s
                
                if arguments_string.empty?
                    arguments_string = "{}"
                end

                # Parse the JSON string
                parsed_arguments = JSON.parse(arguments_string)
            
                if arguments_hash = parsed_arguments.as_h?
                    @arguments = arguments_hash.map do |key, value|
                        ToolCallArgument.new(key, value)
                    end
                elsif arguments_array = parsed_arguments.as_a?
                    @arguments = arguments_array.map { |arg| ToolCallArgument.from_json(arg) }
                else
                    raise "Unexpected format for arguments: Expected Array or Hash, got #{parsed_arguments.class}"
                end
            elsif raw_arguments.is_a?(Array)
                # Already an array
                @arguments = raw_arguments.as_a.map { |arg| ToolCallArgument.from_json(arg) }
            else
                raise "Unexpected type for arguments: #{raw_arguments.class}"
            end
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
              to_json(json) # Delegate to the JSON::Builder version
            end
        end

        def to_json(json : JSON::Builder)
            json.object do
                json.field "id", @id
                json.field "type", @type
                json.field "name", @name

                json.field "function" do
                    json.object do
                        json.field "name", @name
                        
                        args = JSON.build do |js|
                            js.object do
                                @arguments.each do |arg|
                                    js.field arg.name, arg.value
                                end
                            end
                        end

                        json.field "arguments", args.to_s
                    end
                end
            end
        end
    end 
end