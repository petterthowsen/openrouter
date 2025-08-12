module OpenRouter

    struct ToolCallArgument
        include JSON::Serializable

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
    # Helper struct for the function part of a tool call
    struct ToolFunction
        include JSON::Serializable
        
        property name : String
        property arguments : String  # This is a JSON string in the API
        
        def initialize(@name : String, @arguments : String = "{}")
        end
    end

    struct ToolCall
        include JSON::Serializable

        property id : String
        property type : String = "function"
        
        @[JSON::Field(key: "function")]
        property function_data : ToolFunction
        
        # Convenience getters that delegate to function_data
        def name
            function_data.name
        end
        
        def arguments : Array(ToolCallArgument)
            # Parse the arguments JSON string and convert to ToolCallArgument array
            if function_data.arguments.empty?
                return [] of ToolCallArgument
            end
            
            parsed = JSON.parse(function_data.arguments)
            if args_hash = parsed.as_h?
                args_hash.map { |key, value| ToolCallArgument.new(key, value) }
            else
                [] of ToolCallArgument
            end
        end

        def initialize(@id : String, name : String, arguments : Array(ToolCallArgument) = [] of ToolCallArgument, @type : String = "function")
            # Convert arguments array to JSON string for the function_data
            args_json = JSON.build do |json|
                json.object do
                    arguments.each do |arg|
                        json.field arg.name, arg.value
                    end
                end
            end
            
            @function_data = ToolFunction.new(name, args_json)
        end


    end 
end