require "./reasoning"

module OpenRouter

    class CompletionRequest

        # The chat message history
        property messages : Array(Message)?

        # A simple text prompt
        property prompt : String?

        # The model to use.
        # 
        # Browse models at openrouter.ai/models,
        # or use the `get_models` method of the OpenRouter::Client
        property model : String?

        property force_tool_support : Bool = false

        property respond_with_json : Bool = false

        # the stop tokens
        property stop : String | Array(String) | Nil

        # whether to stream the response
        property stream : Bool = false

        # See LLM Parameters (openrouter.ai/docs/parameters)
        property max_tokens : Int32?
        property temperature : Float32?

        # Tool calling
        # Will be passed down as-is for providers implementing OpenAI's interface.
        # For providers with custom interfaces, we transform and map the properties.
        # Otherwise, we transform the tools into a YAML template. The model responds with an assistant message.
        # See models supporting tool calling: openrouter.ai/models?supported_parameters=tools
        property tools : Array(Tool) = [] of Tool

        # Reasoning configuration for models that support reasoning tokens
        property reasoning : Reasoning?

        #### Advanced optional parameters #####
        
        property seed : Int32?

        # Range: (0, 1)
        property top_p : Float32? 

        # Range: (1, Infinity) Not available for OpenAI models
        property top_k : Float32? 

        # Range: (-2, 2)
        property frequency_penalty : Float32? 

        # Range: (-2, 2)
        property presence_penalty : Float32?
        
        # Range: (0, 29)
        property repetition_penalty : Float32?


        property logit_bias_key : Float32?
        property logit_bias_value : Float32?

        property top_logprobs : Int32?

        # Range: [0, 1]
        property min_p : Float32? 
        
        # Range: [0, 1]
        property top_a : Float32?

        # Reduce latency by providing the model with a predicted output
        # https://platform.openai.com/docs/guides/latency-optimization#use-predicted-outputs
        #prediction?: { type: 'content'; content: string; };
        
        #### OpenRouter-only parameters #####
        
        # provider?: ProviderPreferences;
        
        # // See "Prompt Transforms" section at openrouter.ai/docs/transforms
        property transforms : Array(String)?

        # for models and route, See "Model Routing" section at openrouter.ai/docs/model-routing
        property models : Array(String)?
        property route : String?

        # See "Provider Routing" section: openrouter.ai/docs/provider-routing
        property provider : String?
        
        def initialize(prompt : String, model : String? = nil, tools : Array(Tool) = [] of Tool)
            @prompt = prompt
            @model = model
            @tools = tools
        end

        def initialize(messages : Array(Message), model : String? = nil, tools : Array(Tool) = [] of Tool)
            @messages = messages
            @model = model
            @tools = tools
        end

        def add_tool(tool : Tool)
            @tools << tool
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
                to_json(json) # Delegate to the JSON::Builder version
            end
        end

        def to_json(json : JSON::Builder)
            json.object do
                if @prompt
                    json.field "prompt", @prompt
                elsif @messages
                    messages = @messages.not_nil!

                    if messages[0].role == Role::System
                        system_message = messages.shift
                    else
                        system_message = Message.new(role: Role::System, content: "")
                    end

                    if @tools && @force_tool_support
                        system_content = system_message.content_string

                        # append tools to the system message

                        tools_json = @tools.map(&.to_json).join("\n")

                        system_content += <<-MARKDOWN
                        # Tools
                        You have access to the following tool functions:
                        #{tools_json}

                        To perform a tool call, respond with a JSON object containing the tool calls and an optional message. For example:
                        {
                            "message": "Let me see check the current weather in Tokyo for you..."
                            "tool_calls": [
                                {
                                    "function": {
                                        "name": "get_weather",
                                        "arguments": "{ \\"location\\": \\"Tokyo\\" }"
                                    }
                                }
                            ]
                        }
                        MARKDOWN
                        
                        system_message.content = system_content
                    end

                    messages.unshift system_message

                    json.field "messages" do
                        json.array do
                            messages.not_nil!.each_with_index do |message, index|
                                message.to_json(json)
                            end
                        end
                    end
                else
                    raise "Invalid CompletionRequest: Either prompt or messages must be set."
                end

                json.field "model", @model if @model
                json.field "stop", @stop if @stop
                json.field "stream", @stream if @stream
                json.field "max_tokens", @max_tokens if @max_tokens
                json.field "temperature", @temperature if @temperature
                json.field "seed", @seed if @seed
                json.field "top_p", @top_p if @top_p
                json.field "top_k", @top_k if @top_k
                json.field "frequency_penalty", @frequency_penalty if @frequency_penalty
                json.field "presence_penalty", @presence_penalty if @presence_penalty
                json.field "repetition_penalty", @repetition_penalty if @repetition_penalty
                json.field "logit_bias_key", @logit_bias_key if @logit_bias_key
                json.field "logit_bias_value", @logit_bias_value if @logit_bias_value
                json.field "top_logprobs", @top_logprobs if @top_logprobs
                json.field "min_p", @min_p if @min_p
                json.field "top_a", @top_a if @top_a
                json.field "transforms", @transforms if @transforms
                json.field "models", @models if @models
                json.field "route", @route if @route
                json.field "provider", @provider if @provider

                if @tools && !@force_tool_support
                    json.field "tools", @tools if @tools
                end

                if @reasoning
                    json.field "reasoning", @reasoning
                end

                if @respond_with_json
                    json.field "response_format" do
                        json.object do
                            json.field "type", "json_object"
                        end
                    end
                end
            end
        end
    end
end