#!/usr/bin/env bash
# Kaggle-friendly Ollama setup script
# Save as: setup.sh

# NOTE: set -e hata diya, warna koi bhi chhota failure poora script rok dega
set -uo pipefail

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

MODEL="hf.co/HauhauCS/Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF:IQ4_XS"

log() { echo -e "\n[+] $*"; }

# ---------- 1. zstd ----------
log "zstd check..."
if command -v apt-get >/dev/null 2>&1; then
  $SUDO apt-get install -y zstd >/dev/null 2>&1 || true
fi

# ---------- 2. Ollama install ----------
if ! command -v ollama >/dev/null 2>&1; then
  log "Ollama install..."
  curl -fsSL --max-time 120 https://ollama.com/install.sh | sh
else
  log "Ollama pehle se hai: $(command -v ollama)"
fi

# ---------- 3. Ollama serve start (Kaggle me systemd nahi hota) ----------
log "Ollama server check..."

API="http://127.0.0.1:11434/api/tags"
if curl -fsS --max-time 3 "$API" >/dev/null 2>&1; then
  log "Ollama already chal raha hai."
else
  log "Ollama serve background me start..."
  # Kaggle ke liye zaroori env vars
  export OLLAMA_HOST=127.0.0.1:11434
  export OLLAMA_MODELS=/kaggle/working/.ollama/models
  mkdir -p "$OLLAMA_MODELS"
  nohup ollama serve > /kaggle/working/ollama.log 2>&1 &
  echo "  PID: $!"
fi

# ---------- 4. Wait for API ----------
log "Ollama API ready hone ka wait..."
READY=0
for i in $(seq 1 60); do
  if curl -fsS --max-time 3 "$API" >/dev/null 2>&1; then
    READY=1
    log "Ollama ready (${i}s)."
    break
  fi
  sleep 1
done

if [ "$READY" -ne 1 ]; then
  echo "❌ Ollama API 60s me ready nahi hua."
  echo "----- /kaggle/working/ollama.log -----"
  tail -n 40 /kaggle/working/ollama.log || true
  exit 1
fi

# ---------- 5. Pull model ----------
log "Model pull: $MODEL"
ollama pull "$MODEL"

# ---------- 6. (Optional) OpenCode install ----------
# log "OpenCode install..."
# curl -fsSL --max-time 120 https://opencode.ai/v2/install | bash

# ---------- 7. Run model ----------
log "Model run: $MODEL"
ollama run "$MODEL"
