module OpenRouter

    class FunctionParameter
        include JSON::Serializable

        property name : String
        property type : String
        property description : String
        property required : Bool = false
        property items_type : String? = nil

        def initialize(
            name : String,
            type : String,
            description : String,
            required : Bool = false,
            items_type : String? = nil
        )
            @name = name
            @type = type
            @description = description
            @required = required
            @items_type = items_type
        end

        # Custom serialization for complex structure
        def to_json(json : JSON::Builder)
            json.object do
                json.field "type", @type
                json.field "description", @description
                
                # Add items field for array types
                if @type == "array" && @items_type
                    json.field "items" do
                        json.object do
                            json.field "type", @items_type
                        end
                    end
                end
            end
        end
    end

    class Function
        include JSON::Serializable

        property name : String
        property description : String?

        property parameters : Array(FunctionParameter) = [] of FunctionParameter

        def initialize(
            name : String,
            description : String? = nil,
            parameters : Array(FunctionParameter) = [] of FunctionParameter
            )
            @name = name
            @description = description
            @parameters = parameters
        end

        # Custom serialization for complex structure
        def to_json(json : JSON::Builder)
            json.object do
                json.field "name", @name

                if @description
                    json.field "description", @description
                end

                # parameters looks like this:
                # parameters: {
                #   "type": "object",
                #   "properties": {
                #     "location": {
                #       "type": "string",
                #       "description": "The location to search for"
                #     },
                #     "date": {
                #       "type": "string",
                #       "description": "The date to search for"
                #     }
                #   },
                #   "required": ["location"]
                # }
                json.field "parameters" do
                    json.object do
                        json.field "type", "object"
                        json.field "properties" do
                            json.object do
                                @parameters.each do |parameter|
                                    json.field parameter.name do
                                        parameter.to_json(json) # Delegate to FunctionParameter
                                    end
                                end
                            end
                        end
                        
                        # Move required inside parameters object
                        if @parameters.any?(&.required)
                            json.field "required" do
                                json.array do
                                    @parameters.each do |parameter|
                                        if parameter.required
                                            json.string parameter.name
                                        end
                                    end
                                end
                            end
                        end
                    end
                end             
            end
        end
    end

    class Tool
        include JSON::Serializable

        property type : String = "function"
        property function : Function

        def initialize(function : Function)
            @function = function
        end

        def initialize(name : String, description : String? = nil, parameters : Array(FunctionParameter) = [] of FunctionParameter)
            @function = Function.new(name, description, parameters)
        end

        # Custom serialization for complex structure
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