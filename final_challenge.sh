#!/usr/bin/env bash
set -euo pipefail

DURATION=${DURATION:-60}
INTERVAL=${INTERVAL:-5}
URL=${URL:-http://localhost:8080/}

mkdir -p results
CSV="results/metrics_timeseries.csv"

echo "timestamp,replicas,code200,code429,code5xx" > "$CSV"

start=$(date +%s)
end=$((start + DURATION))

echo "[*] Starting controlled incident: duration=${DURATION}s interval=${INTERVAL}s"
echo "[*] Logs will be used as metric source (nginx access.log)."

# limpar logs
sudo truncate -s 0 logs/access.log
sudo truncate -s 0 logs/error.log

# ataque em background
(hey -z ${DURATION}s -c 200 "$URL" > results/final_hey_attack.txt) &
HEY_PID=$!

while [ "$(date +%s)" -lt "$end" ]; do
  ts=$(date +"%Y-%m-%d %H:%M:%S")
  replicas=$(grep -c '^server api' nginx/conf.d/backends/servers.conf 2>/dev/null || echo 1)

  c200=$(awk '$9==200{c++} END{print c+0}' logs/access.log 2>/dev/null || echo 0)
  c429=$(awk '$9==429{c++} END{print c+0}' logs/access.log 2>/dev/null || echo 0)
  c5xx=$(awk '$9>=500 && $9<600{c++} END{print c+0}' logs/access.log 2>/dev/null || echo 0)

  echo "${ts},${replicas},${c200},${c429},${c5xx}" >> "$CSV"
  sleep "$INTERVAL"
done

wait "$HEY_PID" || true

echo "[+] Finished. CSV generated at: $CSV"
echo "[+] hey output: results/final_hey_attack.txt"
