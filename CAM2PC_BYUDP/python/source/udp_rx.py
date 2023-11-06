import socket
import time
import random
import string
# import cv2
import cv2
import numpy as np
import io
from PIL import ImageFile
from PIL import Image as pilImg
from PIL import ImageOps as pilImgOps

# Define the host address
UDP_IP = "192.168.15.15"
UDP_PORT = 11451

def image_inpainting(image, mask):
    # 使用Inpainting算法进行图像修复
    inpainted_image = cv2.inpaint(image, mask, inpaintRadius=3, flags=cv2.INPAINT_TELEA)

    return inpainted_image

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
# sock.close()
sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 72000)
sock.bind((UDP_IP, UDP_PORT))
# sock.setblocking(0)  # Set the socket to be non-blocking
cnt = 0
rank = 0
error = 0
# sock.close()
time.sleep(0.1)
time_start = time.time()
# sock.close()
# while True:
# ImageFile.LOAD_TRUNCATED_IMAGES = True
# data, addr = sock.recvfrom(1500)
# print(data,addr,len(data))
cv2.namedWindow("window", cv2.WINDOW_NORMAL)
jpeg_data = b''
error_cnt = 0;
# sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
# fourcc = cv2.VideoWriter_fourcc(*'mp4v')
# out = cv2.VideoWriter('output.mp4', fourcc, 20.0, (640, 480))
def getRank(data):
    rank = (data[0]%16)*16 + data[1]//16
    return rank
while True and 1:
    if(1):
        data, addr = sock.recvfrom(1500)
        if(data):
            frame_rank = getRank(data[0:3])
            end_state = (data[0]//16 == 8)
            # print(data[1])
            if(error and end_state):
                sock.close()
                sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 0)
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 72000)
                sock.bind((UDP_IP, UDP_PORT))
            elif(error == 0 and (end_state) and frame_rank == rank + 1 and 1):
                # print(1)
                # print(rank + 1)
                jpeg_data = jpeg_data + data[2:]
                sock.close()
                if(data[-2:] == b'\xff\xd9'):
                    # pilImg.open(jpeg_data)
                    if(0):
                        image = pilImg.open(io.BytesIO(jpeg_data))
                        # fixed_image = pilImgOps.exif_transpose(image)
                        # image.show()
                        print(image.format, image.size, image.mode)
                    else:
                        jpeg_array = np.frombuffer(jpeg_data, dtype=np.uint8)
                        image = cv2.imdecode(jpeg_array, cv2.IMREAD_COLOR)
                        cv2.imshow('window', image)
                    # height, width, channels = image.shape
                    # sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 0)
                    # print(f'图像的分辨率为 {width}x{height} 像素')
                    # print(jpeg_data)
                sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 0)
                sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 72000)
                sock.bind((UDP_IP, UDP_PORT))
            elif(error == 0 and frame_rank > 0 and rank + 1 == frame_rank):
                jpeg_data = jpeg_data + data[2:]
                rank = frame_rank
                # print(len(data[2:]))
            elif(frame_rank == 0 and ~end_state):
                jpeg_data = data[2:]
                error = 0
                rank = 0
            else:
                error = 1
            print(frame_rank,end=",")
            if(end_state):
                print("\n")
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

sock.close()
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
# sock.close()
# sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 72000)
sock.bind((UDP_IP, UDP_PORT))
while True and 1:
    # print('working',end=":")
    data, addr = sock.recvfrom(1500)
    if(data):
        # print(getRank(data[0:3]),",",end="")
        if(data[0]//16 == 8):
            sock.close()
            # print("\n")
            print(cnt)
            cnt = cnt + 1
            # print(data," ",addr, " ", clen(data))
            # break
        # break
            sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 0)
            sock.setsockopt(socket.SOL_SOCKET, socket.SO_RCVBUF, 72000)
            sock.bind((UDP_IP, UDP_PORT))
        time_tmp = time.time()
        if(time_tmp - time_start > 1):
            time_start = time_tmp
            # print(cnt)
            cnt = 0
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
    
# out.release()
# 假设你的JPEG数据流是一个名为jpeg_data的字节对象
# jpeg_data = b'...'  # 这里是你的JPEG数据流

# # 将字节对象转换为numpy数组
# jpeg_array = np.frombuffer(jpeg_data, dtype=np.uint8)

# # 使用OpenCV解码JPEG图像
# image = cv2.imdecode(jpeg_array, cv2.IMREAD_COLOR)


sock.close()

# filename = 'jpeg.jpg'
# image = cv2.imread(filename)
# cv2.imshow('Image', image)

cv2.waitKey(0)
cv2.destroyAllWindows()

