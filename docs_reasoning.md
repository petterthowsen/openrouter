---
title: Reasoning Tokens
headline: Reasoning Tokens | Enhanced AI Model Reasoning with OpenRouter
canonical-url: 'https://openrouter.ai/docs/use-cases/reasoning-tokens'
'og:site_name': OpenRouter Documentation
'og:title': Reasoning Tokens - Improve AI Model Decision Making
'og:description': >-
  Learn how to use reasoning tokens to enhance AI model outputs. Implement
  step-by-step reasoning traces for better decision making and transparency.
'og:image':
  type: url
  value: >-
    https://openrouter.ai/dynamic-og?title=Reasoning%20Tokens&description=Enhance%20AI%20model%20outputs%20with%20OpenRouter
'og:image:width': 1200
'og:image:height': 630
'twitter:card': summary_large_image
'twitter:site': '@OpenRouterAI'
noindex: false
nofollow: false
---

import { API_KEY_REF, Model } from '../../../imports/constants';

For models that support it, the OpenRouter API can return **Reasoning Tokens**, also known as thinking tokens. OpenRouter normalizes the different ways of customizing the amount of reasoning tokens that the model will use, providing a unified interface across different providers.

Reasoning tokens provide a transparent look into the reasoning steps taken by a model. Reasoning tokens are considered output tokens and charged accordingly.

Reasoning tokens are included in the response by default if the model decides to output them. Reasoning tokens will appear in the `reasoning` field of each message, unless you decide to exclude them.

<Note title='Some reasoning models do not return their reasoning tokens'>
  While most models and providers make reasoning tokens available in the
  response, some (like the OpenAI o-series and Gemini Flash Thinking) do not.
</Note>

## Controlling Reasoning Tokens

You can control reasoning tokens in your requests using the `reasoning` parameter:

```json
{
  "model": "your-model",
  "messages": [],
  "reasoning": {
    // One of the following (not both):
    "effort": "high", // Can be "high", "medium", or "low" (OpenAI-style)
    "max_tokens": 2000, // Specific token limit (Anthropic-style)

    // Optional: Default is false. All models support this.
    "exclude": false, // Set to true to exclude reasoning tokens from response

    // Or enable reasoning with the default parameters:
    "enabled": true // Default: inferred from `effort` or `max_tokens`
  }
}
```

The `reasoning` config object consolidates settings for controlling reasoning strength across different models. See the Note for each option below to see which models are supported and how other models will behave.

### Max Tokens for Reasoning

<Note title='Supported models'>
  Currently supported by:
  <ul>
    <li>Gemini thinking models</li>
    <li>
      Anthropic models (by using the <code>reasoning.max_tokens</code>{' '}
      parameter)
    </li>
  </ul>
</Note>

For models that support reasoning token allocation, you can control it like this:

- `"max_tokens": 2000` - Directly specifies the maximum number of tokens to use for reasoning

For models that only support `reasoning.effort` (see below), the `max_tokens` value will be used to determine the effort level.

### Reasoning Effort Level

<Note title='Supported models'>
  Currently supported by the OpenAI o-series and Grok models
</Note>

- `"effort": "high"` - Allocates a large portion of tokens for reasoning (approximately 80% of max_tokens)
- `"effort": "medium"` - Allocates a moderate portion of tokens (approximately 50% of max_tokens)
- `"effort": "low"` - Allocates a smaller portion of tokens (approximately 20% of max_tokens)

For models that only support `reasoning.max_tokens`, the effort level will be set based on the percentages above.

### Excluding Reasoning Tokens

If you want the model to use reasoning internally but not include it in the response:

- `"exclude": true` - The model will still use reasoning, but it won't be returned in the response

Reasoning tokens will appear in the `reasoning` field of each message.

### Enable Reasoning with Default Config

To enable reasoning with the default parameters:

- `"enabled": true` - Enables reasoning at the "medium" effort level with no exclusions.

## Legacy Parameters

For backward compatibility, OpenRouter still supports the following legacy parameters:

- `include_reasoning: true` - Equivalent to `reasoning: {}`
- `include_reasoning: false` - Equivalent to `reasoning: { exclude: true }`

However, we recommend using the new unified `reasoning` parameter for better control and future compatibility.

## Examples

### Basic Usage with Reasoning Tokens

<Template data={{
  API_KEY_REF,
  MODEL: "openai/o3-mini"
}}>
<CodeGroup>

```python Python
import requests
import json

url = "https://openrouter.ai/api/v1/chat/completions"
headers = {
    "Authorization": f"Bearer {{API_KEY_REF}}",
    "Content-Type": "application/json"
}
payload = {
    "model": "{{MODEL}}",
    "messages": [
        {"role": "user", "content": "How would you build the world's tallest skyscraper?"}
    ],
    "reasoning": {
        "effort": "high"  # Use high reasoning effort
    }
}

response = requests.post(url, headers=headers, data=json.dumps(payload))
print(response.json()['choices'][0]['message']['reasoning'])
```

```typescript TypeScript
import OpenAI from 'openai';

const openai = new OpenAI({
  baseURL: 'https://openrouter.ai/api/v1',
  apiKey: '{{API_KEY_REF}}',
});

async function getResponseWithReasoning() {
  const response = await openai.chat.completions.create({
    model: '{{MODEL}}',
    messages: [
      {
        role: 'user',
        content: "How would you build the world's tallest skyscraper?",
      },
    ],
    reasoning: {
      effort: 'high', // Use high reasoning effort
    },
  });

  console.log('REASONING:', response.choices[0].message.reasoning);
  console.log('CONTENT:', response.choices[0].message.content);
}

getResponseWithReasoning();
```

</CodeGroup>
</Template>

### Using Max Tokens for Reasoning

For models that support direct token allocation (like Anthropic models), you can specify the exact number of tokens to use for reasoning:

<Template data={{
  API_KEY_REF,
  MODEL: "anthropic/claude-3.7-sonnet"
}}>
<CodeGroup>

```python Python
import requests
import json

url = "https://openrouter.ai/api/v1/chat/completions"
headers = {
    "Authorization": f"Bearer {{API_KEY_REF}}",
    "Content-Type": "application/json"
}
payload = {
    "model": "{{MODEL}}",
    "messages": [
        {"role": "user", "content": "What's the most efficient algorithm for sorting a large dataset?"}
    ],
    "reasoning": {
        "max_tokens": 2000  # Allocate 2000 tokens (or approximate effort) for reasoning
    }
}

response = requests.post(url, headers=headers, data=json.dumps(payload))
print(response.json()['choices'][0]['message']['reasoning'])
print(response.json()['choices'][0]['message']['content'])
```

```typescript TypeScript
import OpenAI from 'openai';

const openai = new OpenAI({
  baseURL: 'https://openrouter.ai/api/v1',
  apiKey: '{{API_KEY_REF}}',
});

async function getResponseWithReasoning() {
  const response = await openai.chat.completions.create({
    model: '{{MODEL}}',
    messages: [
      {
        role: 'user',
        content: "How would you build the world's tallest skyscraper?",
      },
    ],
    reasoning: {
      max_tokens: 2000, // Allocate 2000 tokens (or approximate effort) for reasoning
    },
  });

  console.log('REASONING:', response.choices[0].message.reasoning);
  console.log('CONTENT:', response.choices[0].message.content);
}

getResponseWithReasoning();
```

</CodeGroup>
</Template>

### Excluding Reasoning Tokens from Response

If you want the model to use reasoning internally but not include it in the response:

<Template data={{
  API_KEY_REF,
  MODEL: "deepseek/deepseek-r1"
}}>
<CodeGroup>

```python Python
import requests
import json

url = "https://openrouter.ai/api/v1/chat/completions"
headers = {
    "Authorization": f"Bearer {{API_KEY_REF}}",
    "Content-Type": "application/json"
}
payload = {
    "model": "{{MODEL}}",
    "messages": [
        {"role": "user", "content": "Explain quantum computing in simple terms."}
    ],
    "reasoning": {
        "effort": "high",
        "exclude": true  # Use reasoning but don't include it in the response
    }
}

response = requests.post(url, headers=headers, data=json.dumps(payload))
# No reasoning field in the response
print(response.json()['choices'][0]['message']['content'])
```

```typescript TypeScript
import OpenAI from 'openai';

const openai = new OpenAI({
  baseURL: 'https://openrouter.ai/api/v1',
  apiKey: '{{API_KEY_REF}}',
});

async function getResponseWithReasoning() {
  const response = await openai.chat.completions.create({
    model: '{{MODEL}}',
    messages: [
      {
        role: 'user',
        content: "How would you build the world's tallest skyscraper?",
      },
    ],
    reasoning: {
      effort: 'high',
      exclude: true, // Use reasoning but don't include it in the response
    },
  });

  console.log('REASONING:', response.choices[0].message.reasoning);
  console.log('CONTENT:', response.choices[0].message.content);
}

getResponseWithReasoning();
```

</CodeGroup>
</Template>

### Advanced Usage: Reasoning Chain-of-Thought

This example shows how to use reasoning tokens in a more complex workflow. It injects one model's reasoning into another model to improve its response quality:

<Template data={{
  API_KEY_REF,
}}>
<CodeGroup>

```python Python
import requests
import json

question = "Which is bigger: 9.11 or 9.9?"

url = "https://openrouter.ai/api/v1/chat/completions"
headers = {
    "Authorization": f"Bearer {{API_KEY_REF}}",
    "Content-Type": "application/json"
}

def do_req(model, content, reasoning_config=None):
    payload = {
        "model": model,
        "messages": [
            {"role": "user", "content": content}
        ],
        "stop": "</think>"
    }

    return requests.post(url, headers=headers, data=json.dumps(payload))

# Get reasoning from a capable model
content = f"{question} Please think this through, but don't output an answer"
reasoning_response = do_req("deepseek/deepseek-r1", content)
reasoning = reasoning_response.json()['choices'][0]['message']['reasoning']

# Let's test! Here's the naive response:
simple_response = do_req("openai/gpt-4o-mini", question)
print(simple_response.json()['choices'][0]['message']['content'])

# Here's the response with the reasoning token injected:
content = f"{question}. Here is some context to help you: {reasoning}"
smart_response = do_req("openai/gpt-4o-mini", content)
print(smart_response.json()['choices'][0]['message']['content'])
```

```typescript TypeScript
import OpenAI from 'openai';

const openai = new OpenAI({
  baseURL: 'https://openrouter.ai/api/v1',
  apiKey,
});

async function doReq(model, content, reasoningConfig) {
  const payload = {
    model,
    messages: [{ role: 'user', content }],
    stop: '</think>',
    ...reasoningConfig,
  };

  return openai.chat.completions.create(payload);
}

async function getResponseWithReasoning() {
  const question = 'Which is bigger: 9.11 or 9.9?';
  const reasoningResponse = await doReq(
    'deepseek/deepseek-r1',
    `${question} Please think this through, but don't output an answer`,
  );
  const reasoning = reasoningResponse.choices[0].message.reasoning;

  // Let's test! Here's the naive response:
  const simpleResponse = await doReq('openai/gpt-4o-mini', question);
  console.log(simpleResponse.choices[0].message.content);

  // Here's the response with the reasoning token injected:
  const content = `${question}. Here is some context to help you: ${reasoning}`;
  const smartResponse = await doReq('openai/gpt-4o-mini', content);
  console.log(smartResponse.choices[0].message.content);
}

getResponseWithReasoning();
```

</CodeGroup>
</Template>

## Provider-Specific Reasoning Implementation

### Anthropic Models with Reasoning Tokens

The latest Claude models, such as [anthropic/claude-3.7-sonnet](https://openrouter.ai/anthropic/claude-3.7-sonnet), support working with and returning reasoning tokens.

You can enable reasoning on Anthropic models **only** using the unified `reasoning` parameter with either `effort` or `max_tokens`.

**Note:** The `:thinking` variant is no longer supported for Anthropic models. Use the `reasoning` parameter instead.

#### Reasoning Max Tokens for Anthropic Models

When using Anthropic models with reasoning:

- When using the `reasoning.max_tokens` parameter, that value is used directly with a minimum of 1024 tokens.
- When using the `reasoning.effort` parameter, the budget_tokens are calculated based on the `max_tokens` value.

The reasoning token allocation is capped at 32,000 tokens maximum and 1024 tokens minimum. The formula for calculating the budget_tokens is: `budget_tokens = max(min(max_tokens * {effort_ratio}, 32000), 1024)`

effort_ratio is 0.8 for high effort, 0.5 for medium effort, and 0.2 for low effort.

**Important**: `max_tokens` must be strictly higher than the reasoning budget to ensure there are tokens available for the final response after thinking.

<Note title='Token Usage and Billing'>
  Please note that reasoning tokens are counted as output tokens for billing
  purposes. Using reasoning tokens will increase your token usage but can
  significantly improve the quality of model responses.
</Note>

### Examples with Anthropic Models

#### Example 1: Streaming mode with reasoning tokens

<Template data={{
  API_KEY_REF,
  MODEL: "anthropic/claude-3.7-sonnet"
}}>
<CodeGroup>

```python Python
from openai import OpenAI

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key="{{API_KEY_REF}}",
)

def chat_completion_with_reasoning(messages):
    response = client.chat.completions.create(
        model="{{MODEL}}",
        messages=messages,
        max_tokens=10000,
        reasoning={
            "max_tokens": 8000  # Directly specify reasoning token budget
        },
        stream=True
    )
    return response

for chunk in chat_completion_with_reasoning([
    {"role": "user", "content": "What's bigger, 9.9 or 9.11?"}
]):
    if hasattr(chunk.choices[0].delta, 'reasoning') and chunk.choices[0].delta.reasoning:
        print(f"REASONING: {chunk.choices[0].delta.reasoning}")
    elif chunk.choices[0].delta.content:
        print(f"CONTENT: {chunk.choices[0].delta.content}")
```

```typescript TypeScript
import OpenAI from 'openai';

const openai = new OpenAI({
  baseURL: 'https://openrouter.ai/api/v1',
  apiKey,
});

async function chatCompletionWithReasoning(messages) {
  const response = await openai.chat.completions.create({
    model: '{{MODEL}}',
    messages,
    maxTokens: 10000,
    reasoning: {
      maxTokens: 8000, // Directly specify reasoning token budget
    },
    stream: true,
  });

  return response;
}

(async () => {
  for await (const chunk of chatCompletionWithReasoning([
    { role: 'user', content: "What's bigger, 9.9 or 9.11?" },
  ])) {
    if (chunk.choices[0].delta.reasoning) {
      console.log(`REASONING: ${chunk.choices[0].delta.reasoning}`);
    } else if (chunk.choices[0].delta.content) {
      console.log(`CONTENT: ${chunk.choices[0].delta.content}`);
    }
  }
})();
```

</CodeGroup>
</Template>

## Preserving Reasoning Blocks

<Note title='Model Support'>
  The reasoning_details are currently returned by Anthropic reasoning models,
  but will soon expand to include OpenAI models.
</Note>

If you want to pass reasoning back in context, you must pass reasoning blocks back to the API. This is useful for maintaining the model's reasoning flow and conversation integrity.

Preserving reasoning blocks is useful specifically for tool calling. When models like Claude invoke tools, it is pausing its construction of a response to await external information. When tool results are returned, the model will continue building that existing response. This necessitates preserving reasoning blocks during tool use, for a couple of reasons:

**Reasoning continuity**: The reasoning blocks capture the model's step-by-step reasoning that led to tool requests. When you post tool results, including the original reasoning ensures the model can continue its reasoning from where it left off.

**Context maintenance**: While tool results appear as user messages in the API structure, they're part of a continuous reasoning flow. Preserving reasoning blocks maintains this conceptual flow across multiple API calls.

<Note title='Important for Claude Models'>
  When providing reasoning_details blocks, the entire sequence of consecutive
  reasoning blocks must match the outputs generated by the model during the
  original request; you cannot rearrange or modify the sequence of these blocks.
</Note>

### Example: Preserving Reasoning Blocks with OpenRouter and Claude

<Template data={{
  API_KEY_REF,
  MODEL: 'anthropic/claude-sonnet-4'
}}>
<CodeGroup>

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key="{{API_KEY_REF}}",
)

# First API call with tools
response = client.chat.completions.create(
    model="{{MODEL}}",
    messages=[
        {"role": "user", "content": "What's the weather like in Boston? Then recommend what to wear."}
    ],
    tools=[{
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Get current weather",
            "parameters": {
                "type": "object",
                "properties": {
                    "location": {"type": "string"}
                },
                "required": ["location"]
            }
        }
    }],
    reasoning={"max_tokens": 2000}
)

# Extract the assistant message with reasoning_details
message = response.choices[0].message

# Preserve the complete reasoning_details when passing back
messages = [
    {"role": "user", "content": "What's the weather like in Boston? Then recommend what to wear."},
    {
        "role": "assistant",
        "content": message.content,
        "tool_calls": message.tool_calls,
        "reasoning_details": message.reasoning_details  # Pass back unmodified
    },
    {
        "role": "tool",
        "tool_call_id": message.tool_calls[0].id,
        "content": '{"temperature": 45, "condition": "rainy", "humidity": 85}'
    }
]

# Second API call - Claude continues reasoning from where it left off
response2 = client.chat.completions.create(
    model="{{MODEL}}",
    messages=messages,  # Includes preserved thinking blocks
    tools=tools
)
```

```typescript
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'https://openrouter.ai/api/v1',
  apiKey: '{{API_KEY_REF}}',
});

// First API call with tools
const response = await client.chat.completions.create({
  model: '{{MODEL}}',
  messages: [
    {
      role: 'user',
      content:
        "What's the weather like in Boston? Then recommend what to wear.",
    },
  ],
  tools: [
    {
      type: 'function',
      function: {
        name: 'get_weather',
        description: 'Get current weather',
        parameters: {
          type: 'object',
          properties: {
            location: { type: 'string' },
          },
          required: ['location'],
        },
      },
    },
  ],
  reasoning: { max_tokens: 2000 },
});

// Extract the assistant message with reasoning_details
const message = response.choices[0].message;

// Preserve the complete reasoning_details when passing back
const messages = [
  {
    role: 'user',
    content: "What's the weather like in Boston? Then recommend what to wear.",
  },
  {
    role: 'assistant',
    content: message.content,
    tool_calls: message.tool_calls,
    reasoning_details: message.reasoning_details, // Pass back unmodified
  },
  {
    role: 'tool',
    tool_call_id: message.tool_calls[0].id,
    content: JSON.stringify({
      temperature: 45,
      condition: 'rainy',
      humidity: 85,
    }),
  },
];

// Second API call - Claude continues reasoning from where it left off
const response2 = await client.chat.completions.create({
  model: '{{MODEL}}',
  messages, // Includes preserved thinking blocks
  tools,
});
```

</CodeGroup>
</Template>

For more detailed information about thinking encryption, redacted blocks, and advanced use cases, see [Anthropic's documentation on extended thinking](https://docs.anthropic.com/en/docs/build-with-claude/tool-use#extended-thinking).
