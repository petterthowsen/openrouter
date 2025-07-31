require "./tool_call"

module OpenRouter

    # The role type of a Message
    enum Role
        User
        Assistant
        System
        Tool
    end
    
    # One content part in a multi-modal message.
    alias ContentPart = NamedTuple(type: String, value: String)

    # The content type of a Message
    alias Content = String | Array(ContentPart)

    struct Message
        # Common fields
        property role : Role? = nil
        property content : Content?

        # Optional fields for specific roles
        property tool_call_id : String? # Only for `tool` role
        property name : String?         # Optional for all roles

        property tool_calls : Array(ToolCall)?

        # Reasoning tokens - visible reasoning trace from the model
        property reasoning : String?

        # Reasoning details for preserving reasoning blocks (used in tool calling)
        property reasoning_details : JSON::Any?

        # Initialize for user/assistant/system messages
        def initialize(role : Role, content : Content?, name : String? = nil, tool_call_id : String? = nil, tool_calls : Array(ToolCall)? = nil, reasoning : String? = nil, reasoning_details : JSON::Any? = nil)
            @role = role
            @content = content
            @name = name
            @tool_call_id = tool_call_id
            @tool_calls = tool_calls
            @reasoning = reasoning
            @reasoning_details = reasoning_details

            if role == Role::Tool && tool_call_id == nil
                raise "Tool messages must have a tool_call_id"
            end
        end

        # Get the content, or in case of a multi-modal message, the content of the first part.
        def content_string : String
            if @content.is_a?(Array(ContentPart))
                content_array = @content.as(Array(ContentPart))
                content_array[0][:value]
            elsif @content.is_a?(String)
                @content.as(String)
            else
                ""
            end
        end

        def length : Int32
            if @content.is_a?(Array(ContentPart))
                len = 0
                @content.as(Array(ContentPart)).each do |part|
                    len += part[:type].size + part[:value].size
                end
                len
            elsif @content.is_a?(String)
                @content.as(String).size
            else
                0
            end
        end

        # Create a tool result message.
        # 
        # Role will be Role::Tool
        # @name will be set to tool_call.name
        # @tool_call_id will be set to tool_call.id
        # @content will be set to serializd string of tool_call.arguments.to_json()
        def initialize(tool_call : ToolCall)
            @role = Role::Tool
            @tool_call_id = tool_call.id
            @name = tool_call.name

            # pack arguments to a json object
            args_json = JSON.build do |json|
                json.object do
                    tool_call.arguments.each do |arg|
                        json.field arg.name, arg.value
                    end
                end
            end

            @content = args_json.to_s
        end

        def add_tool_call(tool_call : ToolCall)
            @tool_calls ||= [] of ToolCall
            @tool_calls << tool_call
        end

        def add_tool_call(
            name : String,
            arguments : Array(ToolCallArgument) = [] of ToolCallArgument,
            tool_call_type : String = "function",
            tool_call_id : String? = nil
        )
            tool_call = ToolCall.new(tool_call_id, name, arguments, tool_call_type)
            add_tool_call(tool_call)
        end

        # Check if content is an Array
        def multi_modal? : Bool
            @content.is_a?(Array(ContentPart))
        end

        def self.from_json(json : JSON::Any)
            if json.as_h.has_key? "role"
               role = Role.parse(json["role"].as_s)
            else
                raise "Missing role field in message"
            end

            if json.as_h.has_key? "content"
                # content can be a string, I.E "I am a large language model", or an array of objects, for example:
                # [
                #   {
                #     "type": "text",
                #     "content": "What's in this image?"
                #   },
                #   {
                #     "type": "image_url",
                #     "image_url": {
                #       "url": "http://..." 
                #     }
                #   }
                # ]
                
                # is it a string?
                if json["content"].as_s?
                    content = json["content"].as_s
                elsif json["content"].as_a?
                    # it's an array of objects
                    content = json["content"].as_a.map do |content_part_json|
                        type = content_part_json["type"].as_s
                        # if type is image_url, we look for image_url and use that as content
                        if type == "image_url"
                            type = "image_url"
                            value = content_part_json["image_url"].as_s
                        else
                            value = "unknown"
                        end
                        {
                            type: type,
                            value: value
                        }
                    end
                else
                    content = nil
                end
            else
                raise "Missing content field in message"
            end

            if json.as_h.has_key? "name"
                name = json["name"].as_s
            else
                name = nil
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
            
            if json.as_h.has_key? "tool_calls"
                tool_calls = json["tool_calls"].as_a.map { |tool_call_json| ToolCall.new(tool_call_json) }
            end

            # tool_call_id
            if json.as_h.has_key? "tool_call_id"
                tool_call_id = json["tool_call_id"].as_s
            else
                tool_call_id = nil
            end

            # reasoning
            reasoning = json.as_h.has_key?("reasoning") ? json["reasoning"].as_s? : nil

            # reasoning_details
            reasoning_details = json.as_h.has_key?("reasoning_details") ? json["reasoning_details"] : nil

            Message.new(role, content, name, tool_call_id, tool_calls: tool_calls, reasoning: reasoning, reasoning_details: reasoning_details)
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
                to_json(json)
            end
        end

        def to_json(json : JSON::Builder)
            # Build the JSON object directly
            json.object do
                json.field("role", @role.to_s.downcase)

                if content.is_a?(String)
                    json.field("content", @content)
                else
                    json.field "content", do
                        json.array do
                            @content.as(Array(ContentPart)).each do |content_part|
                                json.object do
                                    type = content_part[:type]
                                    value = content_part[:value]

                                    if type == "image_url"
                                        json.field("type", type)
                                        json.field "image_url" do
                                            json.object do
                                                json.field("url", value)
                                            end
                                        end
                                    else
                                        json.field("type", type)
                                        json.field(type, value)
                                    end
                                end
                            end
                        end
                    end
                end

                # is type tool?
                if @role == Role::Tool
                    json.field("name", @name)
                    json.field("tool_call_id", @tool_call_id)
                else

                    # Include optional fields
                    if @tool_call_id
                        json.field("tool_call_id", @tool_call_id)
                    end

                    if @name
                        json.field("name", @name)
                    end

                    # Serialize tool_calls if not nil
                    if @tool_calls
                        json.field("tool_calls") do
                            json.array do
                                @tool_calls.not_nil!.each { |tool_call| tool_call.to_json(json) }
                            end
                        end
                    end

                    # Include reasoning if present
                    if @reasoning
                        json.field("reasoning", @reasoning)
                    end

                    # Include reasoning_details if present
                    if @reasoning_details
                        json.field("reasoning_details", @reasoning_details)
                    end
                end
            end
        end
    end
end
