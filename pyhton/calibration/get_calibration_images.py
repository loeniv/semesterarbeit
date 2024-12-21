import serial
import time
import cv2
import csv
import os
from create_calib_data_folder import create_calib_data_folder
import numpy as np
from datetime import datetime
from picamera2 import Picamera2
from libcamera import controls
from gpiozero import LED
from scipy.io import savemat

# Define paths for storing data
image_file_path = create_calib_data_folder('/home/robin/Dokumente/Calibration')

# Define scan procedure
dtheta1 = 15
dtheta2 = 45

theta1_min = 0
theta1_max = 45
n_theta1 = int(1 + (theta1_max-theta1_min)/dtheta1)
theta1 = np.linspace(theta1_min, theta1_max, n_theta1)

theta2_min = 0
theta2_max = 360 - dtheta2
n_theta2 = int(1 + (theta2_max-theta2_min)/dtheta2)
theta2 = np.linspace(theta2_min, theta2_max, n_theta2)
poses = n_theta1 * n_theta2

# Create matrix containing angular data
angles_data = np.zeros((poses, 4))

# Configure cameras
capture_res = (2592, 2592)

picam0 = Picamera2(0)
capture_config0 = picam0.create_still_configuration({"size": capture_res}, {"format": "BGR888"})
picam0.configure(capture_config0)
picam0.set_controls({"AeEnable": True ,"AfMode": controls.AfModeEnum.Manual, "LensPosition": 8.0}) # focal distance is 1/5.7 m = 17.5cm
picam0.start()

picam1 = Picamera2(1)
capture_config1 = picam1.create_still_configuration({"size": capture_res}, {"format": "BGR888"})
picam1.configure(capture_config1)
picam1.set_controls({"AeEnable": True, "AfMode": controls.AfModeEnum.Manual, "LensPosition": 8.0}) # focal distance is 1/10 m = 10cm
picam1.start()

# Configure laser
laser = LED(2)

# Open serial port
ser = serial.Serial('/dev/ttyACM0', 115200, timeout=1)

# Allow time for the serial connection to initialize
time.sleep(2)

# Function for reading angles
def is_float(string):
    try:
        float(string)
        return True
    except ValueError:
        return False
    
def read_angles(timeout, angles_set):
    t_begin = time.time()

    # Try until timeout is reached
    while time.time() - t_begin < timeout:
        ser.reset_input_buffer()       
        angles = ser.readline().decode('utf-8').rstrip().split("\t")

        # Check if correct size
        if len(angles) == 2:
            # If both values can be converted -> finish
            if is_float(angles[0]) and is_float(angles[1]):
                break
            else: 
                # Take set values as replacement
                if not is_float(angles[0]):
                    angles[0] = angles_set[0]

                if not is_float(angles[1]):
                    angles[1] = angles_set[1]
        else:
            # Replace both values
            angles = angles_set                 
    return angles

try:  
    # Enable motors
    msg = 'AE1\n'
    ser.write(msg.encode('utf-8'))
    msg = 'BE1\n'
    ser.write(msg.encode('utf-8'))


    # Iterate over each pose
    for i in range(poses):        
        # Send position commands to both motors
        idx_theta1 = i // n_theta2 # stays the same for n_theta2 poses
        idx_theta2 = i % n_theta2 # changes every pose

        angles_set = [str(round(np.deg2rad(theta1[idx_theta1]),5)), str(round(np.deg2rad(theta2[idx_theta2]),5))]

        cmd_A = 'A' + angles_set[0] + '\n'
        cmd_B = 'B' + angles_set[1] + '\n'

        ser.write(cmd_A.encode('utf-8'))
        ser.write(cmd_B.encode('utf-8'))       
        
        print('Pose ' + str(i+1) + '/' + str(poses) + ': ' + str(theta1[idx_theta1]) + ' | ' + str(theta2[idx_theta2]))

        # Wait for movement to be finished
        time.sleep(1)

        # Read actual angles        
        angles = read_angles(5, angles_set)
        theta1_act = angles[0]
        theta2_act = angles[1]        

        # Wait for movement to be finished
        dtheta1 = abs(theta1[idx_theta1] - np.rad2deg(float(theta1_act))) # in degree
        dtheta2 = abs(theta2[idx_theta2] - np.rad2deg(float(theta2_act))) # in degree

        while (dtheta1 > 0.1 or dtheta2 > 0.5):
            angles = read_angles(5, angles_set)
            theta1_act = angles[0]
            theta2_act = angles[1]     
            dtheta1 = abs(theta1[idx_theta1] - np.rad2deg(float(theta1_act))) # in degree
            dtheta2 = abs(theta2[idx_theta2] - np.rad2deg(float(theta2_act))) # in degree

        # Save angles
        angles_data[i,0] = round(float(theta1_act),5)
        angles_data[i,1] = round(float(theta2_act),5)
        angles_data[i,2] = round(np.deg2rad(theta1[idx_theta1]),5)
        angles_data[i,3] = round(np.deg2rad(theta2[idx_theta2]),5)

        # For file name
        if i < 10:
            num = '0' + str(i)
        else:
            num = str(i)

        # Take pictures with laser off
        laser.off()
        picam0.set_controls({"AeEnable": True}) # Turn on auto exposure
        picam1.set_controls({"AeEnable": True}) # Turn on auto exposure
        time.sleep(0.5) # wait for changes to take affect (can take several frames)       


        array0 = picam0.capture_array("main")        
        image0 = cv2.rotate(array0, cv2.ROTATE_90_CLOCKWISE)
        image0 = cv2.cvtColor(image0, cv2.COLOR_RGB2BGR)
        filename = os.path.join(image_file_path, 'right/pattern/distorted/', num + '_right_pattern.png')
        cv2.imwrite(filename, image0) 

        array1 = picam1.capture_array("main")
        image1 = cv2.rotate(array1, cv2.ROTATE_90_COUNTERCLOCKWISE)
        image1 = cv2.cvtColor(image1, cv2.COLOR_RGB2BGR)
        filename = os.path.join(image_file_path, 'left/pattern/distorted/', num + '_left_pattern.png')
        cv2.imwrite(filename, image1) 

        # Take pictures with laser on        
        laser.on()
        picam0.set_controls({"AeEnable": False, "ExposureTime": 1000, "AnalogueGain": 1.0}) # Exposure time is set to 1000µs to get clear line
        picam1.set_controls({"AeEnable": False, "ExposureTime": 1000, "AnalogueGain": 1.0})
        time.sleep(0.5) # wait for changes to take affect (can take several frames)

        array0 = picam0.capture_array("main")        
        image0 = cv2.rotate(array0, cv2.ROTATE_90_CLOCKWISE)
        image0 = cv2.cvtColor(image0, cv2.COLOR_RGB2BGR)
        filename = os.path.join(image_file_path, 'right/laser/distorted/', num + '_right_laser.png')
        cv2.imwrite(filename, image0) 

        array1 = picam1.capture_array("main")
        image1 = cv2.rotate(array1, cv2.ROTATE_90_COUNTERCLOCKWISE)
        image1 = cv2.cvtColor(image1, cv2.COLOR_RGB2BGR)
        filename = os.path.join(image_file_path, 'left/laser/distorted/', num + '_left_laser.png')
        cv2.imwrite(filename, image1) 

        laser.off()

finally:
    # Move motor to zero position
    msg = 'A0\n'
    ser.write(msg.encode('utf-8'))
    msg = 'B0\n'
    ser.write(msg.encode('utf-8'))
    time.sleep(1)
    # Disable motors and close serial port
    msg = 'AE0\n'
    ser.write(msg.encode('utf-8'))
    msg = 'BE0\n'
    ser.write(msg.encode('utf-8'))
    ser.close()
    
    # Turn off laser
    laser.off()

    print("Scan finished!")