#!/usr/bin/env bash
set -Eeuo pipefail

MODEL='hf.co/HauhauCS/Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF:IQ4_XS'
OLLAMA_URL='http://127.0.0.1:11434/api/tags'
LOG_FILE="$HOME/ollama-server.log"

printf '\n[1/5] Installing zstd...\n'
sudo apt-get install -y zstd

printf '\n[2/5] Installing Ollama...\n'
curl -fsSL https://ollama.com/install.sh | sh

export OLLAMA_HOST='127.0.0.1:11434'

printf '\n[3/5] Starting Ollama server in the background...\n'
if curl -fsS --connect-timeout 2 "$OLLAMA_URL" >/dev/null 2>&1; then
  echo 'Ollama API is already responding.'
else
  nohup env OLLAMA_HOST="$OLLAMA_HOST" ollama serve >"$LOG_FILE" 2>&1 </dev/null &
  SERVER_PID=$!
  READY=0

  for _ in {1..60}; do
    if curl -fsS --connect-timeout 1 "$OLLAMA_URL" >/dev/null 2>&1; then
      READY=1
      break
    fi
    if ! kill -0 "$SERVER_PID" 2>/dev/null; then
      break
    fi
    sleep 1
  done

  if [[ "$READY" -ne 1 ]]; then
    echo 'ERROR: Ollama API did not start within 60 seconds.' >&2
    echo "---- Ollama server log: $LOG_FILE ----" >&2
    if [[ -f "$LOG_FILE" ]]; then
      tail -n 80 "$LOG_FILE" >&2
    else
      echo 'Server log was not created.' >&2
    fi
    exit 1
  fi
fi

printf '\n[4/5] Downloading model: %s\n' "$MODEL"
ollama pull "$MODEL"

printf '\n[5/5] Installing OpenCode...\n'
curl -fsSL https://opencode.ai/v2/install | bash

printf '\nStarting Ollama CLI...\n'
ollama
