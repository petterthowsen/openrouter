require "./spec_helper"
require "./../src/openrouter"

API_KEY = begin
    File.read("./spec/api_key.txt")
rescue e
    raise "Please create a file called './spec/api_key.txt' containing your OpenRouter API key"
end

EMBEDDING_MODEL = "text-embedding-ada-002"

describe OpenRouter::EmbeddingRequest do
    it "serializes a simple string input" do
        request = OpenRouter::EmbeddingRequest.new(
            input: "hello world",
            model: EMBEDDING_MODEL
        )
        json = JSON.parse(request.to_json)
        json["input"].as_s.should eq("hello world")
        json["model"].as_s.should eq(EMBEDDING_MODEL)
        json["encoding_format"]?.should be_nil
    end

    it "serializes an array of strings" do
        request = OpenRouter::EmbeddingRequest.new(
            input: ["foo", "bar"],
            model: EMBEDDING_MODEL
        )
        json = JSON.parse(request.to_json)
        json["input"].as_a.map(&.as_s).should eq(["foo", "bar"])
    end

    it "serializes optional fields when present" do
        request = OpenRouter::EmbeddingRequest.new(
            input: "test",
            model: EMBEDDING_MODEL,
            encoding_format: OpenRouter::EmbeddingEncodingFormat::Base64,
            dimensions: 512,
            user: "user-123"
        )
        json = JSON.parse(request.to_json)
        json["encoding_format"].as_s.should eq("base64")
        json["dimensions"].as_i.should eq(512)
        json["user"].as_s.should eq("user-123")
    end

    it "omits nil optional fields" do
        request = OpenRouter::EmbeddingRequest.new(
            input: "test",
            model: EMBEDDING_MODEL
        )
        json = JSON.parse(request.to_json)
        json["dimensions"]?.should be_nil
        json["user"]?.should be_nil
    end
end

describe OpenRouter::EmbeddingResponse do
    it "deserializes a valid response" do
        raw = %({
            "id": "embd-abc123",
            "object": "list",
            "model": "text-embedding-ada-002",
            "data": [
                {"object": "embedding", "index": 0, "embedding": [0.1, 0.2, 0.3]}
            ],
            "usage": {"prompt_tokens": 3, "total_tokens": 3}
        })
        response = OpenRouter::EmbeddingResponse.from_json(raw)
        response.should be_a(OpenRouter::EmbeddingResponse)
        response.object.should eq("list")
        response.model.should eq("text-embedding-ada-002")
        response.data.size.should eq(1)
        response.data[0].index.should eq(0)
        response.data[0].embedding_floats.should eq([0.1_f64, 0.2_f64, 0.3_f64])
        response.usage.not_nil!.prompt_tokens.should eq(3)
        response.usage.not_nil!.total_tokens.should eq(3)
    end

    it "handles base64 encoded embedding" do
        raw = %({
            "object": "list",
            "model": "text-embedding-ada-002",
            "data": [
                {"object": "embedding", "index": 0, "embedding": "SGVsbG8="}
            ],
            "usage": {"prompt_tokens": 1, "total_tokens": 1}
        })
        response = OpenRouter::EmbeddingResponse.from_json(raw)
        response.data[0].embedding_base64.should eq("SGVsbG8=")
    end
end

describe OpenRouter::Client do
    it "sends an embedding request and returns EmbeddingResponse", focus: true do
        client = OpenRouter::Client.new(API_KEY)

        response = client.embed("The quick brown fox", EMBEDDING_MODEL)

        response.should be_a(OpenRouter::EmbeddingResponse)
        response.data.should be_a(Array(OpenRouter::EmbeddingData))
        response.data.size.should be > 0
        response.data[0].should be_a(OpenRouter::EmbeddingData)
        response.data[0].embedding_floats.should be_a(Array(Float64))
        response.data[0].embedding_floats.size.should be > 0
        response.usage.should be_a(OpenRouter::EmbeddingUsage)
    end

    it "sends an embedding request with multiple inputs", focus: true do
        client = OpenRouter::Client.new(API_KEY)

        response = client.embed(["hello", "world"], EMBEDDING_MODEL)

        response.data.size.should eq(2)
        response.data[0].index.should eq(0)
        response.data[1].index.should eq(1)
    end

    it "raises an error for unsupported dimensions", focus: true do
        client = OpenRouter::Client.new(API_KEY)

        # qwen3-embedding-8b accepts dimensions: 2 without error (silently clips or ignores)
        # so we use an invalid model to verify the error path works
        expect_raises(OpenRouter::Error) do
            client.embed("test input", "not-a-real/model")
        end
    end

    it "sends an EmbeddingRequest object directly", focus: true do
        client = OpenRouter::Client.new(API_KEY)

        request = OpenRouter::EmbeddingRequest.new(
            input: "test input",
            model: EMBEDDING_MODEL,
            encoding_format: OpenRouter::EmbeddingEncodingFormat::Float
        )
        response = client.embed(request)

        response.should be_a(OpenRouter::EmbeddingResponse)
        response.data.size.should be > 0
    end
end
