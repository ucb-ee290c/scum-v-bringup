import pandas as pd
import matplotlib.pyplot as plt


cnt_n, cnt_p = [], []

# Reconstructing the approach to parse data directly based on the structure observed from the file content
with open("./logs/counter_regs_96m_10m_dcoff_0.08_idac_69_2.6ua.txt", 'r') as file:
    for line in file:
        # Checking if the line contains relevant data to avoid parsing non-data lines
        if "CNT_N:" in line and "CNT_P:" in line:
            parts = line.strip().split()
            cnt_n_value = int(parts[1])  # Extracting CNT_N value
            cnt_p_value = int(parts[3])  # Extracting CNT_P value
            cnt_n.append(cnt_n_value)
            cnt_p.append(cnt_p_value)

# Creating DataFrame from the parsed data
data_corrected = pd.DataFrame({
    "CNT_N": cnt_n,
    "CNT_P": cnt_p
})

# Calculating the difference between CNT_P and CNT_N
data_corrected["CNT_P_MINUS_N"] = data_corrected["CNT_P"] - data_corrected["CNT_N"]

# Plotting the corrected data
fig, axs = plt.subplots(3, 1, figsize=(10, 12))

# Plot for COUNTER_P
axs[0].plot(data_corrected["CNT_P"], label="COUNTER_P", color="blue")
axs[0].set_title("COUNTER_P")
axs[0].set_xlabel("Sample Index")
axs[0].set_ylabel("COUNTER_P Value")
axs[0].legend()

# Plot for COUNTER_N
axs[1].plot(data_corrected["CNT_N"], label="COUNTER_N", color="green")
axs[1].set_title("COUNTER_N")
axs[1].set_xlabel("Sample Index")
axs[1].set_ylabel("COUNTER_N Value")
axs[1].legend()

# Plot for COUNTER_P - COUNTER_N
axs[2].plot(data_corrected["CNT_P_MINUS_N"], label="COUNTER_P - COUNTER_N", color="red")
axs[2].set_title("COUNTER_P - COUNTER_N")
axs[2].set_xlabel("Sample Index")
axs[2].set_ylabel("Difference (COUNTER_P - COUNTER_N)")
axs[2].legend()

plt.tight_layout()
plt.show()
