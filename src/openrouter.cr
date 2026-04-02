require "./openrouter/client"
require "./openrouter/errors"
require "./openrouter/types/model"
require "./openrouter/types/completion_request"
require "./openrouter/types/response"
require "./openrouter/types/message"
require "./openrouter/types/model"
require "./openrouter/types/tool"
require "./openrouter/types/embedding_request"
require "./openrouter/types/embedding_response"

# Provides an HTTP Client for the OpenRouter API (https://openrouter.ai)
module OpenRouter
  VERSION = "1.2.0"
end