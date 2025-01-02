module OpenRouter

    struct ToolCallArgument
        getter name : String
        getter value : String

        def initialize(name : String, value : String)
            @name = name
            @value = value
        end

        def self.from_json(json : JSON::Any)
            name = json["name"].as_s
            value = json["value"].as_s
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
                json.field "value", @value
            end
        end
    end

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
        def initialize(json : JSON::Any)
            @id = json["id"].as_s
            @type = json["type"].as_s
            @name = json["function"]["name"].as_s
        
            # Handle `arguments`
            raw_arguments = json["function"]["arguments"]
            
            puts "parsing tool_call arguments\n"
            puts raw_arguments.inspect

            if raw_arguments.try &.as_s?
                arguments_string = raw_arguments.as_s
                # Parse the JSON string
                parsed_arguments = JSON.parse(arguments_string)
            
                puts "Parsed arguments: #{parsed_arguments.inspect} (class: #{parsed_arguments.class})"
            
                if arguments_hash = parsed_arguments.as_h?
                    @arguments = arguments_hash.map do |key, value|
                        ToolCallArgument.new(key, value.as_s)
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