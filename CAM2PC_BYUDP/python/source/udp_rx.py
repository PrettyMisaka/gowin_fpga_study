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
ImageFile.LOAD_TRUNCATED_IMAGES = True
# data, addr = sock.recvfrom(1500)
# print(data,addr,len(data))
cv2.namedWindow("window", cv2.WINDOW_NORMAL)
if(1):
    # try:
    while True:
        try:
        # if(1):
            data, addr = sock.recvfrom(1500)
            if(data):
                # print(data[1])
                if(data[1] == 0 and error == 0):
                    print(1)
                    # print(rank + 1)
                    jpeg_data = jpeg_data + data[2:]
                    # pilImg.open(jpeg_data)
                    if(1):
                        image = pilImg.open(io.BytesIO(jpeg_data))
                        fixed_image = pilImgOps.exif_transpose(image)
                        fixed_image.show()
                    else:
                        # print(jpeg_data)
                        
                        jpeg_array = np.frombuffer(jpeg_data, np.uint8)
                        image = cv2.imdecode(jpeg_array, cv2.IMREAD_COLOR)
                        cv2.imshow('window', image)
                        # height, width, channels = image.shape
                        # print(f'图像的分辨率为 {width}x{height} 像素')
                    # with open('jpeg.jpg', 'wb') as f:
                    #     f.write(jpeg_data)
                    # break
                    # print(jpeg_data)
                    # break
                elif(data[1] > 1 and rank + 1 == data[1]):
                    jpeg_data = jpeg_data + data[2:]
                    rank = data[1]
                    # print(len(data[2:]))
                elif(data[1] == 1):
                    jpeg_data = data[2:]
                    error = 0
                    rank = 1
                else:
                    error = 1
        except:
            pass
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
        # break
while True and 0:
    try:
        data, addr = sock.recvfrom(1500)
        if(data):
            # print(data[1],",",end="\n")
            if(data[1] == 0):
                # break
                # print("\n")
                # print(cnt)
                cnt = cnt + 1
    except:
        pass
            # print(data," ",addr, " ", clen(data))
            # break
        # break
        time_tmp = time.time()
        if(time_tmp - time_start > 1):
            time_start = time_tmp
            print(cnt)
            cnt = 0
    

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
# while True:
# #     # print(1)
#     pass
