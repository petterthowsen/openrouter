module OpenRouter

    struct EmbeddingUsage
        include JSON::Serializable

        getter prompt_tokens : Int32
        getter total_tokens : Int32
    end

    # A single embedding vector in the response data array
    struct EmbeddingData
        getter object : String
        getter index : Int32

        # Embedding is either an array of floats or a base64 string
        @raw_embedding : Array(Float64) | String

        def initialize(@object : String, @index : Int32, @raw_embedding : Array(Float64) | String)
        end

        # Returns the embedding as floats. Raises if the embedding is base64 encoded.
        def embedding_floats : Array(Float64)
            case e = @raw_embedding
            in Array(Float64) then e
            in String         then raise "Embedding is base64 encoded; use #embedding_base64"
            end
        end

        # Returns the raw base64 string. Raises if the embedding is an array of floats.
        def embedding_base64 : String
            case e = @raw_embedding
            in String         then e
            in Array(Float64) then raise "Embedding is float array; use #embedding_floats"
            end
        end

        def self.new(pull : JSON::PullParser)
            object = ""
            index = 0
            raw_embedding : Array(Float64) | String = [] of Float64

            pull.read_object do |key|
                case key
                when "object" then object = pull.read_string
                when "index"  then index = pull.read_int.to_i
                when "embedding"
                    case pull.kind
                    when .string? then raw_embedding = pull.read_string
                    when .begin_array?
                        floats = [] of Float64
                        pull.read_array { floats << pull.read_float }
                        raw_embedding = floats
                    else
                        pull.skip
                    end
                else
                    pull.skip
                end
            end

            new(object, index, raw_embedding)
        end
    end

    struct EmbeddingResponse
        include JSON::Serializable

        getter id : String?
        getter object : String
        getter model : String
        getter data : Array(EmbeddingData)
        getter usage : EmbeddingUsage?
    end
end
