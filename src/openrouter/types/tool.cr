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

        # Custom deserialization to handle complex parameters structure
        def self.from_json(string_or_io)
            parser = JSON::PullParser.new(string_or_io)
            new(parser)
        end

        def self.new(parser : JSON::PullParser)
            name = ""
            description = nil
            parameters = [] of FunctionParameter

            parser.read_object do |key|
                case key
                when "name"
                    name = parser.read_string
                when "description"
                    description = parser.read_string_or_null
                when "parameters"
                    # Parse the complex parameters object structure
                    parser.read_object do |param_key|
                        case param_key
                        when "properties"
                            parser.read_object do |prop_name|
                                param_type = ""
                                param_description = ""
                                items_type = nil

                                parser.read_object do |prop_key|
                                    case prop_key
                                    when "type"
                                        param_type = parser.read_string
                                    when "description"
                                        param_description = parser.read_string
                                    when "items"
                                        parser.read_object do |items_key|
                                            case items_key
                                            when "type"
                                                items_type = parser.read_string
                                            else
                                                parser.skip
                                            end
                                        end
                                    else
                                        parser.skip
                                    end
                                end

                                parameters << FunctionParameter.new(
                                    name: prop_name,
                                    type: param_type,
                                    description: param_description,
                                    required: false, # Will be set below
                                    items_type: items_type
                                )
                            end
                        when "required"
                            required_params = [] of String
                            parser.read_array do
                                required_params << parser.read_string
                            end
                            # Mark required parameters
                            parameters.each do |param|
                                param.required = required_params.includes?(param.name)
                            end
                        else
                            parser.skip
                        end
                    end
                else
                    parser.skip
                end
            end

            new(name, description, parameters)
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

        # Custom deserialization to handle complex function structure
        def self.from_json(string_or_io)
            parser = JSON::PullParser.new(string_or_io)
            new(parser)
        end

        def self.new(parser : JSON::PullParser)
            type = "function"
            function = nil

            parser.read_object do |key|
                case key
                when "type"
                    type = parser.read_string
                when "function"
                    function = Function.new(parser)
                else
                    parser.skip
                end
            end

            raise "Missing function in Tool" unless function
            tool = new(function)
            tool.type = type
            tool
        end
    end
end