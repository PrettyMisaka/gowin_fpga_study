import socket
import time
import random
import string
# import cv2

# Define the host address
UDP_IP = "192.168.15.15"
UDP_PORT = 11452

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))
cnt = 0

while True:
    data, addr = sock.recvfrom(65507)
    if data:
        print(data)
        break
    else:
        pass
    
sock.close()