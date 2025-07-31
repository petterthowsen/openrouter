module OpenRouter
    # Represents the reasoning configuration for models that support reasoning tokens
    struct Reasoning
        # Effort level for reasoning: "high", "medium", or "low" (OpenAI-style)
        property effort : String?

        # Specific token limit for reasoning (Anthropic-style)
        property max_tokens : Int32?

        # Whether to exclude reasoning tokens from response (default: false)
        property exclude : Bool = false

        # Enable reasoning with default parameters (default: inferred from effort or max_tokens)
        property enabled : Bool?

        def initialize(effort : String? = nil, max_tokens : Int32? = nil, exclude : Bool = false, enabled : Bool? = nil)
            @effort = effort
            @max_tokens = max_tokens
            @exclude = exclude
            @enabled = enabled

            # Validate effort level if provided
            if effort && !["high", "medium", "low"].includes?(effort)
                raise "Invalid effort level: #{effort}. Must be 'high', 'medium', or 'low'"
            end

            # Validate that only one of effort or max_tokens is set
            if effort && max_tokens
                raise "Cannot specify both effort and max_tokens"
            end
        end

        def to_json(io : IO)
            JSON.build(io) do |json|
                to_json(json)
            end
        end

        def to_json(json : JSON::Builder)
            json.object do
                json.field "effort", @effort if @effort
                json.field "max_tokens", @max_tokens if @max_tokens
                json.field "exclude", @exclude if @exclude != false
                json.field "enabled", @enabled if @enabled
            end
        end

        # Create a reasoning config with high effort
        def self.high(exclude : Bool = false)
            new(effort: "high", exclude: exclude)
        end

        # Create a reasoning config with medium effort
        def self.medium(exclude : Bool = false)
            new(effort: "medium", exclude: exclude)
        end

        # Create a reasoning config with low effort
        def self.low(exclude : Bool = false)
            new(effort: "low", exclude: exclude)
        end

        # Create a reasoning config with specific max tokens
        def self.with_max_tokens(max_tokens : Int32, exclude : Bool = false)
            new(max_tokens: max_tokens, exclude: exclude)
        end

        # Create a reasoning config with default parameters
        def self.enabled(exclude : Bool = false)
            new(enabled: true, exclude: exclude)
        end
    end
end