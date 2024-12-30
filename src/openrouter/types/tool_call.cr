module OpenRouter
    struct ToolCall
        getter id : String
        getter type : String
        getter name : String
        getter arguments : JSON::Any

        def initialize(json : JSON::Any)
            @id = json["id"].as_s
            @type = json["type"].as_s
            @name = json["name"].as_s
            @arguments = json["arguments"]
        end
    end 
end