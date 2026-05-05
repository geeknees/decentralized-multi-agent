#!/usr/bin/env bash
# ABOUTME: Tests the LLM provider adapter used by agent loops
# ABOUTME: Verifies claude, codex, ollama, custom command, and OpenAI-compatible providers

SCRIPTS_DIR="$(dirname "$0")/../scripts"

MOCK_DIR=$(mktemp -d)
cleanup_llm_call() { rm -rf "$MOCK_DIR"; }
trap cleanup_llm_call EXIT

cat > "$MOCK_DIR/claude" << 'MOCK'
#!/usr/bin/env bash
if [ "$1" != "--print" ]; then
  echo "unexpected claude args: $*" >&2
  exit 2
fi
prompt=$(cat)
printf '{"provider":"claude","prompt":"%s"}\n' "$prompt"
MOCK
chmod +x "$MOCK_DIR/claude"

cat > "$MOCK_DIR/codex" << 'MOCK'
#!/usr/bin/env bash
output_file=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o|--output-last-message)
      shift
      output_file="$1"
      ;;
  esac
  shift || true
done
if [ -z "$output_file" ]; then
  echo "missing output file" >&2
  exit 2
fi
prompt=$(cat)
printf '{"provider":"codex","prompt":"%s"}\n' "$prompt" > "$output_file"
MOCK
chmod +x "$MOCK_DIR/codex"

cat > "$MOCK_DIR/ollama" << 'MOCK'
#!/usr/bin/env bash
if [ "$1" != "run" ] || [ "$2" != "local-model" ]; then
  echo "unexpected ollama args: $*" >&2
  exit 2
fi
prompt=$(cat)
printf '{"provider":"ollama","prompt":"%s"}\n' "$prompt"
MOCK
chmod +x "$MOCK_DIR/ollama"

cat > "$MOCK_DIR/curl" << 'MOCK'
#!/usr/bin/env bash
cat >/dev/null
printf '{"choices":[{"message":{"content":"{\\"provider\\":\\"openai-compatible\\"}"}}]}\n'
MOCK
chmod +x "$MOCK_DIR/curl"

cat > "$MOCK_DIR/custom_llm" << 'MOCK'
#!/usr/bin/env bash
prompt=$(cat)
printf '{"provider":"custom","prompt":"%s"}\n' "$prompt"
MOCK
chmod +x "$MOCK_DIR/custom_llm"

export PATH="$MOCK_DIR:$PATH"

result=$(printf 'hello claude' | LLM_PROVIDER=claude "$SCRIPTS_DIR/llm_call.sh")
assert_contains '"provider":"claude"' "$result" "llm_call claude provider"
assert_contains 'hello claude' "$result" "llm_call passes prompt to claude"

result=$(printf 'hello codex' | LLM_PROVIDER=codex PROJECT_ROOT="$(dirname "$0")/.." "$SCRIPTS_DIR/llm_call.sh")
assert_contains '"provider":"codex"' "$result" "llm_call codex provider"
assert_contains 'hello codex' "$result" "llm_call passes prompt to codex"

result=$(printf 'hello ollama' | LLM_PROVIDER=ollama LLM_MODEL=local-model "$SCRIPTS_DIR/llm_call.sh")
assert_contains '"provider":"ollama"' "$result" "llm_call ollama provider"
assert_contains 'hello ollama' "$result" "llm_call passes prompt to ollama"

result=$(printf 'hello custom' | LLM_CMD="$MOCK_DIR/custom_llm" "$SCRIPTS_DIR/llm_call.sh")
assert_contains '"provider":"custom"' "$result" "llm_call custom command"
assert_contains 'hello custom' "$result" "llm_call passes prompt to custom command"

result=$(printf 'hello api' | LLM_PROVIDER=openai-compatible LLM_ENDPOINT=http://localhost:11434/v1/chat/completions LLM_MODEL=local-model "$SCRIPTS_DIR/llm_call.sh")
assert_contains '"provider":"openai-compatible"' "$result" "llm_call openai-compatible provider"
