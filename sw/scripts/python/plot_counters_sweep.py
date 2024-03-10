import pandas as pd
import matplotlib.pyplot as plt

# Let's read the new file and parse the data considering the specified conditions: only plot IDAC codes from 50 to 80.
# Each section is marked by "Logging counters, IDAC: <value>".

file_path_idac = "./logs/counter_regs_96m_10m_dcoff_0.3_idac_sweep_128_note_69.txt"

# Initialize variables to hold the parsed data
cnt_n_sections, cnt_p_sections = {}, {}
current_idac = None
bound_min = 69
bound_max = 69

with open(file_path_idac, 'r') as file:
    for line in file:
        if line.startswith("Logging counters, IDAC:"):
            # Extract IDAC value
            current_idac = int(line.strip().split()[-1])
            # Initialize lists for this IDAC if within the specified range
            if bound_min <= current_idac <= bound_max:
                cnt_n_sections[current_idac] = []
                cnt_p_sections[current_idac] = []
        elif "CNT_N:" in line and "CNT_P:" in line and current_idac is not None and bound_min <= current_idac <= bound_max:
            parts = line.strip().split()
            cnt_n_sections[current_idac].append(int(parts[1]))
            cnt_p_sections[current_idac].append(int(parts[3]))

# Now, we'll plot the data for each IDAC within the specified range
fig, axs = plt.subplots(len(cnt_n_sections), 1, figsize=(10, 3 * len(cnt_n_sections)), squeeze=False)

for i, (idac, cnt_n) in enumerate(cnt_n_sections.items()):
    cnt_p = cnt_p_sections[idac]
    cnt_p_minus_n = [p - n for p, n in zip(cnt_p, cnt_n)]

    # Plot COUNTER_P for this IDAC
    axs[i, 0].plot(cnt_p, "s-", label=f"COUNTER_P, IDAC: {idac}", color="blue")
    axs[i, 0].plot(cnt_n, "s-", label=f"COUNTER_N, IDAC: {idac}", color="green")
    axs[i, 0].plot(cnt_p_minus_n, "s-", label=f"COUNTER_P - COUNTER_N, IDAC: {idac}", color="red")
    axs[i, 0].set_title(f"IDAC: {idac} - COUNTER_P and COUNTER_N")
    axs[i, 0].set_xlabel("Sample Index")
    axs[i, 0].set_ylabel("Counter Values")
    axs[i, 0].legend()

plt.tight_layout()
plt.show()
