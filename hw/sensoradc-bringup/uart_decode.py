import serial
import struct
import numpy as np
import matplotlib.pyplot as plt
from collections import deque
import time

# Configuration
serial_port = 'COM4'  # Replace with your serial port
baud_rate = 1000000
buffer_size = 500

# Open the serial port
ser = serial.Serial(serial_port, baud_rate)

# Create a deque for the rolling buffer
data_buffer = deque(maxlen=buffer_size)

# Create a figure and axis for plotting
fig, ax = plt.subplots()
line, = ax.plot([], [])
ax.set_xlim(0, buffer_size)
ax.set_ylim(-2**19, 2**19 - 1)  # Adjust the limits based on your data range
ax.set_xlabel('Sample')
ax.set_ylabel('Value')
ax.set_title('Live Plot')

# Update the plot
def update_plot():
    line.set_data(range(len(data_buffer)), data_buffer)
    ax.relim()
    ax.autoscale_view()
    fig.canvas.draw()
    fig.canvas.flush_events()
    plt.pause(0.001)  # Add a short pause to allow plot update

# Read and process the data
while True:
    # Read bytes until the marker byte (0xAA) is found
    marker_found = False
    while not marker_found:
        byte = ser.read(1)
        if byte == b'\xAA':
            marker_found = True
    
    # Read the next 3 bytes
    data = ser.read(3)
    
    if len(data) == 3:
        # Combine the three bytes to form a 20-bit value
        value_20bit = (data[0] << 16) | (data[1] << 8) | data[2]
        
        # Convert the 20-bit value to a signed integer
        if value_20bit & (1 << 19):
            value_20bit = value_20bit - (1 << 20)
        
        # Print the value to the console
        print("Received value:", value_20bit)
        
        # Append the value to the data buffer
        data_buffer.append(value_20bit)
        
        # Update the plot
        update_plot()
    else:
        print("Incomplete data received. Skipping.")

# Close the serial port
ser.close()