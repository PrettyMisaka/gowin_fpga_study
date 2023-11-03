import socket
import time
import random
import string
# import cv2
import cv2
import numpy as np

# Define the host address
UDP_IP = "192.168.15.15"
UDP_PORT = 11451

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))
sock.setblocking(0)  # Set the socket to be non-blocking
cnt = 0
# sock.close()
time.sleep(0.1)
time_start = time.time()
# sock.close()
# while True:
if(1):
    time_tmp = time.time()
    # try:
    if True :
        data, addr = sock.recvfrom(1500)
        # print(data[1],",",end="")
        if(data[1] == 1):
            print(data[1])
            jpeg_data = data[2:]
            while(True):
                data, addr = sock.recvfrom(1500)
                print(data[1])
                if(data[1] == 0):
                    jpeg_data = jpeg_data + data[2:]
                    jpeg_array = np.frombuffer(jpeg_data, dtype=np.uint8)
                    image = cv2.imdecode(jpeg_array, cv2.IMREAD_COLOR)
                    cv2.imshow('Image', image)
                    height, width, channels = image.shape
                    print(f'图像的分辨率为 {width}x{height} 像素')
                    break
                if(data[1] > 1):
                    jpeg_data = jpeg_data + data[2:]
                elif(data[1] == 1):
                    jpeg_data = data[2:]
                    # break
            # break
            # print("\n")
            # print(data[1],",",end="\n")
            # print(cnt)
            # cnt = cnt + 1
            # print(data," ",addr, " ", clen(data))
            # break
        # break
    # except:
    #     pass
    # if(time_tmp - time_start > 1):
    #     time_start = time_tmp
    #     print(cnt)
    #     cnt = 0
# while True:
#     # print(1)
#     pass
    

# 假设你的JPEG数据流是一个名为jpeg_data的字节对象
jpeg_data = b'...'  # 这里是你的JPEG数据流

# 将字节对象转换为numpy数组
jpeg_array = np.frombuffer(jpeg_data, dtype=np.uint8)

# 使用OpenCV解码JPEG图像
image = cv2.imdecode(jpeg_array, cv2.IMREAD_COLOR)


sock.close()