#!/usr/bin/env bash
set -e

sudo apt-get install -y zstd
curl -fsSL https://ollama.com/install.sh | sh

nohup ollama serve > "$HOME/ollama-server.log" 2>&1 &

until curl -fsS http://127.0.0.1:11434/api/tags >/dev/null 2>&1; do
  sleep 1
done

ollama pull hf.co/HauhauCS/Qwen3.8-27B-Uncensored-HauhauCS-Aggressive-MTP-GGUF:IQ4_XS
curl -fsSL https://opencode.ai/v2/install | bash
ollama
