module OpenRouter

    struct FunctionDescription
        getter name : String
        getter description : String?

        def initialize(name : String, description : String? = nil)
            @name = name
            @description = description
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
              to_json(json) # Delegate to the JSON::Builder version
            end
        end

        def to_json(json : JSON::Builder)
            json.object do
                json.field "name", @name

                if @description
                    json.field "description", @description
                end
            end
        end
    end

    struct Tool
        getter type : String = "function"
        function : FunctionDescription

        def initialize(function : FunctionDescription)
            @function = function
        end

        def initialize(name : String, description : String? = nil)
            @function = FunctionDescription.new(name, description)
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
              to_json(json) # Delegate to the JSON::Builder version
            end
        end
        
        def to_json(json : JSON::Builder)
            json.object do
                json.field "type", @type
                json.field "function" do
                    @function.to_json(json)
                end
            end
        end
    end

end