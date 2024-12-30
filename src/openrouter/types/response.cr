module OpenRouter

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
    end

    abstract struct Choice
        getter finish_reason : String?
    end

    struct NonChatChoice < Choice
        getter text : String

        def initialize(json : JSON::Any)
            @text = json["text"].as_s
        end
    end

    struct NonStreamingChoice < Choice
        getter message : Message

        def initialize(json : JSON::Any)
            @message = Message.from_json(json["message"])
        end
    end

    struct StreamingChoice < Choice
        getter delta : Message

        def initialize(json : JSON::Any)
            @delta = Message.from_json(json["delta"])
        end
    end

    # Represents a response from 
    struct Response
        getter id : String
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

        def initialize(json : JSON::Any)
            @id = json["id"].as_s
            @created = json["created"].as_i
            @model = json["model"].as_s
            
            # loop through choices
            # and add them to the choices array
            json["choices"].as_a.each do |choice_json|
                if choice_json.as_h.has_key? "text" != nil
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