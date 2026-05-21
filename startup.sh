#!/bin/bash
# startup.sh - Orchestrates the entire container lifecycle

# Accept model name as the first argument, default to gemma4:e4b if empty
MODEL_NAME="${1:-gemma4:e4b}"

echo "Starting AEU Infrastructure..."
echo "Using model: ${MODEL_NAME}"

# 1. System Setup
apt-get update && apt-get install -y nodejs npm git zstd lshw curl

# 2. Setup Ollama (if needed)
if [ ! -f /usr/local/bin/ollama ]; then 
    curl -fsSL https://ollama.com/install.sh | sh
fi

# 3. Start Ollama in background
OLLAMA_HOST=0.0.0.0 ollama serve > /var/log/ollama.log 2>&1 &
echo "Waiting for Ollama to initialize..."
sleep 15

# 4. Pull and warm up model
echo "Warming up model ${MODEL_NAME}..."
ollama run "${MODEL_NAME}" "hi"

echo "==================================="
ollama list
echo "==================================="

# 5. Start Tunnel Agent
export VPS_IP='187.127.164.190'
nohup node /workspace/tunnel/agent.js > /var/log/tunnel-agent.log 2>&1 &
sleep 1
cat /var/log/tunnel-agent.log

echo "Everything started. Container ready."
tail -f /dev/null
