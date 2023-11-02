import socket
import time
import random
import string
# import cv2

# Define the host address
UDP_IP = "192.168.15.15"
UDP_PORT = 11451

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))
sock.setblocking(0)  # Set the socket to be non-blocking
cnt = 0
# sock.close()
time.sleep(0.1)

# sock.close()
while True:
# if(1):
    try:
        data, addr = sock.recvfrom(65535)
        # print(data[0],data[1],",",end="")
        if(data[0] == 128):
            print(data[1],",",end="\n")
            # print(data," ",addr, " ", len(data))
            # break
        # break
    except:
        data = None
        # print("none")
        time.sleep(0.1)
        # break
        pass

sock.close()