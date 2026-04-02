module OpenRouter

    enum EmbeddingEncodingFormat
        Float
        Base64

        def to_s : String
            case self
            when Float  then "float"
            when Base64 then "base64"
            else "float"
            end
        end
    end

    # Request body for POST /embeddings
    class EmbeddingRequest
        property input : String | Array(String)
        property model : String
        property encoding_format : EmbeddingEncodingFormat?
        property dimensions : Int32?
        property user : String?

        def initialize(
            @input : String | Array(String),
            @model : String,
            @encoding_format : EmbeddingEncodingFormat? = nil,
            @dimensions : Int32? = nil,
            @user : String? = nil
        )
        end

        def to_json(json : JSON::Builder)
            json.object do
                json.field "model", @model

                json.field "input" do
                    case i = @input
                    in String       then json.string i
                    in Array(String) then json.array { i.each { |s| json.string s } }
                    end
                end

                json.field "encoding_format", @encoding_format.to_s if @encoding_format
                json.field "dimensions", @dimensions if @dimensions
                json.field "user", @user if @user
            end
        end

        def to_json : String
            JSON.build { |json| to_json(json) }
        end
    end
end
