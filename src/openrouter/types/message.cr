require "./tool_call"

module OpenRouter
    enum Role
        User
        Assistant
        System
        Tool
    end

    struct Message
        # Common fields
        property role : Role? = nil
        property content : String

        # Optional fields for specific roles
        property tool_call_id : String? # Only for `tool` role
        property name : String?         # Optional for all roles

        property tool_calls : Array(ToolCall)?

        # Initialize for user/assistant/system messages
        def initialize(role : Role, content : String, name : String? = nil, tool_call_id : String? = nil)
            @role = role
            @content = content
            @name = name
            @tool_call_id = tool_call_id

            if role == Role::Tool && tool_call_id == nil
                raise "Tool messages must have a tool_call_id"
            end

            if role != Role::Tool && tool_call_id != nil
                raise "Non-tool messages cannot have a tool_call_id"
            end
        end

        def self.from_json(json : JSON::Any)
            if json.as_h.has_key? "role"
               role = Role.parse(json["role"].as_s)
            else
                raise "Missing role field in message"
            end

            if json.as_h.has_key? "content"
                content = json["content"].as_s
            else
                raise "Missing content field in message"
            end

            if json.as_h.has_key? "name"
                name = json["name"].as_s
            else
                name = nil
            end

            if json.as_h.has_key? "tool_call_id"
                tool_call_id = json["tool_call_id"].as_s
            else
                tool_call_id = nil
            end

            Message.new(role, content, name, tool_call_id)
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
                to_json(json)
            end
        end

        def to_json(json : JSON::Builder)
            # Build the JSON object directly
            json.object do
                json.field("role", @role.to_s)
                json.field("content", @content)

                # Include optional fields
                json.field("tool_call_id", @tool_call_id) if @tool_call_id
                json.field("name", @name) if @name
            end
        end
    end
end
