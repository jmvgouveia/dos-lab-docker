#!/usr/bin/env bash
set -euo pipefail

MAX=${MAX:-5}
INTERVAL=${INTERVAL:-5}
WINDOW_LINES=${WINDOW_LINES:-2000}

mkdir -p nginx/conf.d/backends results

log="results/C_autoscale.log"
echo "[*] autoscaler started $(date)" | tee -a "$log"

count_backends() {
  grep -c '^server api' nginx/conf.d/backends/servers.conf 2>/dev/null || echo 0
}

reload_lb() {
  docker exec lb nginx -s reload >/dev/null
}

add_backend() {
  local n="$1"
  echo "[+] scaling OUT -> api${n} $(date)" | tee -a "$log"
  docker run -d --name "api${n}" --network dos-lab-docker_labnet nginx:stable >/dev/null
  echo "server api${n}:80;" >> nginx/conf.d/backends/servers.conf
  reload_lb
}

calc_429_ratio() {
  tail -n "$WINDOW_LINES" logs/access.log 2>/dev/null | awk '
    {total++}
    $9==429 {c429++}
    END {
      if (total==0) {print "0 0 0"; exit}
      printf "%d %d %.2f\n", total, c429+0, (c429/total*100)
    }'
}

while true; do
  b=$(count_backends)
  read -r total c429 ratio <<<"$(calc_429_ratio)"
  echo "$(date +%H:%M:%S) backends=$b total=$total 429=$c429 ratio429=${ratio}%" | tee -a "$log"

  # Escala se 429 > 20%
  if python3 - <<PY
ratio=float("$ratio")
print(1 if ratio>20.0 else 0)
PY
  then
    if [ "$b" -lt "$MAX" ]; then
      add_backend $((b+1))
    fi
  fi

  sleep "$INTERVAL"
done
