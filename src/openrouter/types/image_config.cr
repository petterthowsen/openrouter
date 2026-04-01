module OpenRouter

    # Configuration for image generation requests.
    #
    # Used with `CompletionRequest#image_config` when requesting image output
    # from models that support the `image` modality.
    struct ImageConfig
        include JSON::Serializable

        # Aspect ratio of the generated image, e.g. "1:1", "16:9", "21:9"
        @[JSON::Field(emit_null: false)]
        property aspect_ratio : String?

        # Resolution of the generated image: "0.5K", "1K", "2K", or "4K"
        @[JSON::Field(emit_null: false)]
        property image_size : String?

        def initialize(@aspect_ratio : String? = nil, @image_size : String? = nil)
        end
    end
end
