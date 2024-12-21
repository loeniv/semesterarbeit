import time
import cv2
import csv
import os
import numpy as np
from picamera2 import Picamera2
from libcamera import controls

# Create a folder to store the captured images and the capture times
image_file_path = "/home/robin/dev/IndiPrint/scanner/capture_time/"

# Configure camera and resolutions
capture_res = []
for mp in np.arange(0.25, 13, 0.25):
    x = 4/3 * np.sqrt(mp * 1e6) # mp = x * y
    y = 9/16 * x # only 16/9
    capture_res.append((int(round(x)),int(round(y))))

picam = Picamera2(0)

# Iterate over each capture resolution
for res in capture_res:
    # Set the capture resolution
    picam.stop()
    capture_config = picam.create_still_configuration({"size": res}, {"format": "BGR888"}, buffer_count=2)
    picam.configure(capture_config)
    picam.set_controls({"AfMode": controls.AfModeEnum.Manual, "LensPosition": 8.0})
    picam.start()
    print(f"Capture resolution set to {res}")

    # Take 10 pictures and measure the capture time for each
    # Then calculate the average capture time and file size
    capture_times = []
    file_sizes = []
    for i in range(25):
        # Create a unique filename for the picture
        filename = f"capture_{res[0]}x{res[1]}_{i}.png"

        # Create a new folder for the current resolution if it doesn't exist
        if not os.path.exists(os.path.join(image_file_path, f"{res[0]}x{res[1]}")):
            os.makedirs(os.path.join(image_file_path, f"{res[0]}x{res[1]}"))

        path = os.path.join(image_file_path, f"{res[0]}x{res[1]}", filename)

        # Take picture, save it and measure capture time
        start_time = time.time()

        array = picam.capture_array("main") # Capture image as array
        image = cv2.cvtColor(array, cv2.COLOR_RGB2BGR) # Convert to BGR format        
        cv2.imwrite(path, image) # Save image

        # Measure capture time
        end_time = time.time()
        capture_time = end_time - start_time
        capture_times.append(capture_time)

        # Measure file size
        file_stats = os.stat(path)
        file_size = file_stats.st_size / (1024 * 1024) # in Megabyte
        file_sizes.append(file_size)
        print(f"Picture {i+1} captured in {capture_time:.2f} seconds")
        

    # Exclute the first picture from the average captur time calculation
    capture_times = capture_times[1:]
    # Exclude outliers from the average capture time calculation if value is more than 1s
    capture_times = [x for x in capture_times if x < 1]

    average_capture_time = sum(capture_times) / len(capture_times)
    average_file_size = sum(file_sizes) / len(file_sizes)

    # Save the average capture time to a file
    path = os.path.join(image_file_path, "capture_times.csv")
    with open(path, mode="a", newline="") as file:
        writer = csv.writer(file)
        writer.writerow([f"{res[0]}x{res[1]}", res[0]*res[1], average_capture_time, average_file_size])
    