import pandas as pd
import matplotlib.pyplot as plt

df = pd.read_csv("results/metrics_timeseries.csv")
df["timestamp"] = pd.to_datetime(df["timestamp"])

# calcular por intervalo (diferença entre amostras)
for col in ["code200","code429","code5xx"]:
    df[col+"_delta"] = df[col].diff().fillna(0)

# Error rate (percentual no intervalo)
df["total_delta"] = df["code200_delta"] + df["code429_delta"] + df["code5xx_delta"]
df["error_rate_pct"] = (df["code5xx_delta"] / df["total_delta"].replace(0, 1)) * 100

# --- replicas vs tempo ---
plt.figure()
plt.plot(df["timestamp"], df["replicas"])
plt.title("Replicas vs Time")
plt.xlabel("Time")
plt.ylabel("Replicas")
plt.xticks(rotation=30)
plt.tight_layout()
plt.savefig("results/replicas_vs_time.png", dpi=150)

# --- error rate vs tempo ---
plt.figure()
plt.plot(df["timestamp"], df["error_rate_pct"])
plt.title("Error Rate (5xx) vs Time")
plt.xlabel("Time")
plt.ylabel("5xx Error Rate (%)")
plt.xticks(rotation=30)
plt.tight_layout()
plt.savefig("results/error_rate_vs_time.png", dpi=150)

# --- 429 vs tempo (muito útil no teu caso!) ---
plt.figure()
ratio429 = (df["code429_delta"] / df["total_delta"].replace(0, 1)) * 100
plt.plot(df["timestamp"], ratio429)
plt.title("Rate Limit (429) Ratio vs Time")
plt.xlabel("Time")
plt.ylabel("429 Ratio (%)")
plt.xticks(rotation=30)
plt.tight_layout()
plt.savefig("results/429_ratio_vs_time.png", dpi=150)

print("[+] Graphs generated:")
print(" - results/replicas_vs_time.png")
print(" - results/error_rate_vs_time.png")
print(" - results/429_ratio_vs_time.png")
