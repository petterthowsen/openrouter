module OpenRouter

    # Represents a language model retrieved from the OpenRouter API via the `/models` endpoint
    struct Model
        getter id : String
        getter name : String
        getter created : Int32
        getter description : String

        getter pricing_prompt : String
        getter pricing_completion : String
        getter pricing_request : String
        getter pricing_image : String

        getter context_length : Int32

        getter architecture_tokenizer : String

        @architecture_instruct_type : String? = nil
        getter architecture_instruct_type : String?

        getter architecture_modality : String

        @top_provider_context_length : Int32? = nil
        getter top_provider_context_length : Int32?

        @top_provider_max_completion_tokens : Int32? = nil
        getter top_provider_max_completion_tokens : Int32?

        getter top_provider_is_moderated : Bool

        @per_request_limits_prompt_tokens : Int32? = nil
        getter per_request_limits_prompt_tokens

        @per_request_limits_completion_tokens : Int32? = nil
        getter per_request_limits_completion_tokens

        # Creates a new Model object from a JSON response from the OpenRouter API.
        # 
        # The JSON response from the OpenRouter API should be formatted as follows:
        # ```json
        # {
        #     "id": "string",
        #     "name": "string",
        #     "created": 0,
        #     "description": "string",
        #     "pricing": {
        #       "prompt": "string",
        #       "completion": "string",
        #       "request": "string",
        #       "image": "string"
        #     },
        #     "context_length": 0,
        #     "architecture": {
        #       "tokenizer": "Router",
        #       "instruct_type": "none",
        #       "modality": "text->text"
        #     },
        #     "top_provider": {
        #       "context_length": 0,
        #       "max_completion_tokens": 0,
        #       "is_moderated": true
        #     },
        #     "per_request_limits": {
        #       "prompt_tokens": null,
        #       "completion_tokens": null
        #     }
        # }
        # ```
        def initialize(json : JSON::Any)
            @id = json["id"].as_s
            @name = json["name"].as_s
            @created = json["created"].as_i
            @description = json["description"].as_s

            @pricing_prompt = json["pricing"]["prompt"].as_s
            @pricing_completion = json["pricing"]["completion"].as_s
            @pricing_request = json["pricing"]["request"].as_s
            @pricing_image = json["pricing"]["image"].as_s

            @context_length = json["context_length"].as_i

            @architecture_tokenizer = json["architecture"]["tokenizer"].as_s

            if json["architecture"]["instruct_type"] != nil
                @architecture_instruct_type = json["architecture"]["instruct_type"].as_s
            end

            @architecture_modality = json["architecture"]["modality"].as_s
            
            top_provider = json["top_provider"]
            
            @top_provider_context_length = top_provider["context_length"].as_i?

            if top_provider["max_completion_tokens"] != nil
                @top_provider_max_completion_tokens = top_provider["max_completion_tokens"].as_i
            end

            @top_provider_is_moderated = top_provider["is_moderated"].as_bool

            if json["per_request_limits"] != nil
                per_request_limits = json["per_request_limits"]
                
                if per_request_limits["prompt_tokens"] != nil
                    @per_request_limits_prompt_tokens = per_request_limits["prompt_tokens"].as_i
                end

                if per_request_limits["completion_tokens"] != nil
                    @per_request_limits_completion_tokens = per_request_limits["completion_tokens"].as_i
                end
            end
        end

        def to_s
            "Model(id=#{id}, name=#{name}, description=#{description})"
        end
    end
end