#!/usr/bin/env bash
# ------------------------------------------------------------
# Ollama + Model + OpenCode Install & Run Script
# Save as: install_ollama.sh
# Run:    chmod +x install_ollama.sh && ./install_ollama.sh
# ------------------------------------------------------------

set -euo pipefail

# Root ya sudo decide karo
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

# Yahan apna model set karo. Agar naam galat ho to sirf ye line badlo.
MODEL="hf.co/HauhauCS/Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF:IQ4_XS"

log() {
  echo -e "\n[+] $*"
}

# 1. Basic dependencies: curl, zstd
if ! command -v curl >/dev/null 2>&1; then
  log "curl install ho raha hai..."
  $SUDO apt-get update -y
  $SUDO apt-get install -y curl
fi

if command -v apt-get >/dev/null 2>&1; then
  log "zstd check/install..."
  $SUDO apt-get update -y
  $SUDO apt-get install -y zstd
fi

# 2. Ollama install
if ! command -v ollama >/dev/null 2>&1; then
  log "Ollama install ho raha hai..."
  curl -fsSL https://ollama.com/install.sh | sh
else
  log "Ollama pehle se installed hai."
fi

# 3. Ollama service start / check
log "Ollama service start/check..."

if command -v systemctl >/dev/null 2>&1; then
  if $SUDO systemctl enable --now ollama 2>/dev/null; then
    log "systemd se Ollama service start ho gayi."
  else
    log "systemd service start nahi hui, manual fallback..."
    if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
      nohup ollama serve > /tmp/ollama.log 2>&1 &
      disown || true
    fi
  fi
else
  if ! curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    log "Ollama serve background me start ho raha hai..."
    nohup ollama serve > /tmp/ollama.log 2>&1 &
    disown || true
  fi
fi

# 4. Ollama API ready hone ka wait
log "Ollama API ka wait..."
for i in {1..30}; do
  if curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; then
    log "Ollama API ready hai."
    break
  fi
  sleep 1
  if [ "$i" -eq 30 ]; then
    echo "❌ Ollama API start nahi hua. Log check karo: /tmp/ollama.log" >&2
    exit 1
  fi
done

# 5. Model pull
log "Model pull ho raha hai: $MODEL"
ollama pull "$MODEL"

# 6. OpenCode install (agar nahi chahiye to is block ko comment kar do)
log "OpenCode install ho raha hai..."
curl -fsSL https://opencode.ai/v2/install | bash

# 7. Model run
log "Model run ho raha hai: $MODEL"
ollama run "$MODEL"
