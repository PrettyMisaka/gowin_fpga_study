import socket
import time
import random
import string
import cv2

# Define the host address
UDP_IP = "127.0.0.1"
UDP_PORT = 11454

# Function to generate a random string of random length
def get_random_string(string_len = 1400, isRandom = True):
    if isRandom:
        length = random.randint(0, string_len)  # Random string length between 0 and 1400
    else:
        length = string_len
    ascii_chars = string.ascii_letters + string.digits + string.punctuation + ' '  # All ASCII characters
    result_str = ''.join(random.choice(ascii_chars) for i in range(length))
    return result_str

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))

def recvUDPData():
    sock.bind((UDP_IP, UDP_PORT))
            # print("data is empty")

cv2.namedWindow("window", cv2.WINDOW_NORMAL)

cnt = 0

while True:
    str = get_random_string(string_len=65500)
    print(len(str))
    msg = str.encode('utf-8', 'ignore')
    sock.sendto(msg,(UDP_IP, UDP_PORT))
    time.sleep(1)
    while True:
        data, addr = sock.recvfrom(65507)
        if data:
            break
        else:
            pass
    if(data == msg):
        print("recv success")
    else:
        print("error")
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cv2.destroyAllWindows()
sock.close()