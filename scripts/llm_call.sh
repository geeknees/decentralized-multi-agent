#!/usr/bin/env bash
# ABOUTME: Dispatches a prompt from stdin to the configured LLM backend
# ABOUTME: Supports claude, codex, ollama, custom commands, and OpenAI-compatible APIs

set -euo pipefail

LLM_PROVIDER="${LLM_PROVIDER:-claude}"
LLM_MODEL="${LLM_MODEL:-}"
LLM_ENDPOINT="${LLM_ENDPOINT:-}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

ruby_cmd() {
  if command -v mise >/dev/null 2>&1; then
    mise exec -- ruby "$@"
  else
    ruby "$@"
  fi
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found for LLM provider '$LLM_PROVIDER': $1" >&2
    exit 127
  fi
}

PROMPT="$(cat)"

if [ -n "${LLM_CMD:-}" ]; then
  printf '%s' "$PROMPT" | sh -c "$LLM_CMD"
  exit $?
fi

case "$LLM_PROVIDER" in
  claude)
    require_command claude
    printf '%s' "$PROMPT" | claude --print
    ;;
  codex)
    require_command codex
    output_file="$(mktemp)"
    cleanup_codex_output() { rm -f "$output_file"; }
    trap cleanup_codex_output EXIT

    codex_args=(
      exec
      --ephemeral
      --sandbox read-only
      --ask-for-approval never
      --cd "$PROJECT_ROOT"
      --output-last-message "$output_file"
    )
    if [ -n "$LLM_MODEL" ]; then
      codex_args+=(--model "$LLM_MODEL")
    fi

    printf '%s' "$PROMPT" | codex "${codex_args[@]}" - >/dev/null
    cat "$output_file"
    ;;
  ollama)
    require_command ollama
    if [ -z "$LLM_MODEL" ]; then
      echo "LLM_MODEL is required when LLM_PROVIDER=ollama" >&2
      exit 2
    fi
    printf '%s' "$PROMPT" | ollama run "$LLM_MODEL"
    ;;
  openai-compatible|openai_compatible)
    require_command curl
    if [ -z "$LLM_ENDPOINT" ] || [ -z "$LLM_MODEL" ]; then
      echo "LLM_ENDPOINT and LLM_MODEL are required for OpenAI-compatible providers" >&2
      exit 2
    fi

    body="$(PROMPT="$PROMPT" MODEL="$LLM_MODEL" ruby_cmd -rjson -e '
      puts JSON.dump({
        model: ENV.fetch("MODEL"),
        messages: [
          {
            role: "system",
            content: "Return only the JSON action object requested by the prompt. Do not include prose."
          },
          { role: "user", content: ENV.fetch("PROMPT") }
        ],
        temperature: (ENV["LLM_TEMPERATURE"] || "0.2").to_f
      })
    ')"

    curl_args=(
      -sS "$LLM_ENDPOINT"
      -H 'Content-Type: application/json'
    )
    if [ -n "${LLM_API_KEY:-}" ]; then
      curl_args+=(-H "Authorization: Bearer $LLM_API_KEY")
    fi
    curl_args+=(-d "$body")

    response="$(curl "${curl_args[@]}")"

    RESPONSE="$response" ruby_cmd -rjson -e '
      data = JSON.parse(ENV.fetch("RESPONSE"))
      content = data.dig("choices", 0, "message", "content") ||
                data.dig("choices", 0, "text") ||
                data["response"]
      puts(content || "")
    '
    ;;
  *)
    echo "Unknown LLM_PROVIDER: $LLM_PROVIDER" >&2
    exit 2
    ;;
esac
