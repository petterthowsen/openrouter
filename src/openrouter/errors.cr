# src/openrouter/errors.cr
module OpenRouter
  class Error < Exception
    def initialize(@message : String)
      super(@message)
    end
  end

  class BadRequestError < Error; end         # 400
  class UnauthorizedError < Error; end       # 401
  class PaymentRequiredError < Error; end    # 402
  class ForbiddenError < Error; end          # 403
  class RequestTimeoutError < Error; end     # 408
  class TooManyRequestsError < Error; end    # 429
  class BadGatewayError < Error; end         # 502
  class ServiceUnavailableError < Error; end # 503

  # Generic API error
  class ApiError < Error
    getter code : Int32? = nil
    
    def initialize(message : String, code : Int32? = nil)
      super(@message)
      @code = code
    end
  end
  
end