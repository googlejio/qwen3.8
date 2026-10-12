pkill -f ollama 2>/dev/null
sleep 2
unset CUDA_VISIBLE_DEVICES
export PATH=$PATH:/opt/bin
export LD_LIBRARY_PATH=/usr/local/nvidia/lib64:$LD_LIBRARY_PATH
ldconfig 2>/dev/null
ollama serve > /tmp/ollama.log 2>&1 &
sleep 8
echo "✅ Ollama GPU ready!"
grep -i "inference compute" /tmp/ollama.log
