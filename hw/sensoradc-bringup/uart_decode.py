import serial
import struct
import numpy as np
import matplotlib.pyplot as plt
from collections import deque

# Configuration
serial_port = 'COM4'  # Replace with your serial port
baud_rate = 115200
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
    fig.canvas.draw()
    fig.canvas.flush_events()

# Read and process the data
while True:
    # Read 4 bytes from the serial port
    data = ser.read(4)
    
    # Check if the marker byte is received
    if data[3] == 0xAA:
        # Combine the first three bytes to form a 20-bit value
        value_20bit = (data[0] << 12) | (data[1] << 4) | (data[2] >> 4)
        
        # Convert the 20-bit value to a signed integer
        if value_20bit & (1 << 19):
            value_20bit = value_20bit - (1 << 20)
        
        # Print the value to the console
        print("Received value:", value_20bit)
        
        # Append the value to the data buffer
        data_buffer.append(value_20bit)
        
        # Update the plot
        update_plot()

# Close the serial port
ser.close()