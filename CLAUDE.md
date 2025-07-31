# OpenRouter Crystal Library Architecture

## Overview
This is a Crystal library that provides an HTTP API client for the OpenRouter API (https://openrouter.ai). The library follows a modular, object-oriented design with clear separation of concerns.

## Project Structure

```
src/
├── openrouter.cr                 # Main module entry point
├── openrouter/
    ├── client.cr                 # Core HTTP client implementation
    ├── errors.cr                 # Custom exception classes
    └── types/                    # Data structures and models
        ├── completion_request.cr # Request payload structure
        ├── message.cr           # Chat message representation
        ├── model.cr             # Model metadata structure
        ├── response.cr          # Response structures
        ├── tool.cr              # Tool/function calling support
        └── tool_call.cr         # Tool call execution data
```

## Core Components

### 1. OpenRouter::Client (`src/openrouter/client.cr`)
The main API client class that handles HTTP communication with the OpenRouter API.

**Key features:**
- Authentication via API key
- Optional app identification (app_name, app_url)
- Model listing (`get_models`)
- Chat completions (`complete`)
- Low-level HTTP methods (`get`, `post`)
- Comprehensive error handling

**Base URL:** `https://openrouter.ai/api/v1`

### 2. Type System (`src/openrouter/types/`)

#### CompletionRequest
Represents a chat completion request with support for:
- Simple text prompts or structured messages
- Model selection and parameters
- Tool/function calling
- Advanced parameters (temperature, top_p, etc.)
- OpenRouter-specific features (provider routing, transforms)

#### Response & Choices
Response structures that handle:
- Non-streaming responses (`NonStreamingChoice`)
- Streaming responses (`StreamingChoice`) 
- Non-chat responses (`NonChatChoice`)
- Usage statistics (`Usage`)

#### Message
Chat message representation supporting:
- Multiple roles (User, Assistant, System, Tool)
- Multi-modal content (text, images)
- Tool calls and responses

#### Model
Metadata structure for available models including:
- Pricing information
- Context length limits
- Architecture details
- Provider constraints

#### Tool System
Function calling support with:
- `Tool`: Tool definition with function schema
- `Function`: Function metadata and parameters
- `FunctionParameter`: Parameter type definitions
- `ToolCall`: Execution data for tool invocations

### 3. Error Handling (`src/openrouter/errors.cr`)
Comprehensive error hierarchy mapping HTTP status codes:
- `BadRequestError` (400)
- `UnauthorizedError` (401)
- `PaymentRequiredError` (402)
- `ForbiddenError` (403)
- `RequestTimeoutError` (408)
- `TooManyRequestsError` (429)
- `BadGatewayError` (502)
- `ServiceUnavailableError` (503)
- `ApiError` (generic API errors)

## Key Design Patterns

### 1. Struct-based Value Types
Most data structures are implemented as `struct` for performance and immutability:
- `Model`, `Message`, `Response`, `Usage`, etc.

### 2. JSON Serialization
All types implement `to_json` methods with both IO and JSON::Builder variants for flexible serialization.

### 3. Factory Methods
Complex initialization is handled through factory methods:
- `Response.from_request` for processing API responses
- `Message.from_json` for parsing message data

### 4. Polymorphic Choices
Abstract `Choice` class with specialized implementations for different response types.

### 5. Error-first Design
Explicit error handling with custom exception types for different failure modes.

## Special Features

### Tool Calling Support
The library supports both native OpenAI-style tool calling and a "forced tool support" mode that transforms tool definitions into system prompts for models without native tool support.

### Multi-modal Messages
Support for messages containing both text and image content through the `ContentPart` system.

### Provider Routing
OpenRouter-specific features like provider selection, model routing, and request transforms.

## Usage Patterns

1. **Basic Chat Completion:**
   ```crystal
   client = OpenRouter::Client.new(api_key)
   response = client.complete("Hello", "gpt-3.5-turbo")
   ```

2. **Advanced Chat with Tools:**
   ```crystal
   request = CompletionRequest.new(messages, model)
   request.add_tool(tool)
   response = client.complete(request)
   ```

3. **Model Discovery:**
   ```crystal
   models = client.get_models
   ```

The architecture emphasizes type safety, comprehensive error handling, and flexible configuration while maintaining a clean, intuitive API surface.