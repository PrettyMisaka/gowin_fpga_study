import cv2
import socket
import numpy as np

# Set up UDP socket
UDP_IP = "127.0.0.1"
UDP_PORT = 5005
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind((UDP_IP, UDP_PORT))

cv2.namedWindow("window", cv2.WINDOW_NORMAL)

while True:
    # Receive a compressed frame over UDP
    data, addr = sock.recvfrom(65507)

    # Decode the compressed frame to an image
    img = cv2.imdecode(np.frombuffer(data, dtype=np.uint8), cv2.IMREAD_COLOR)

    # Display the image
    cv2.imshow("window", img)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Release the resources
cv2.destroyAllWindows()
sock.close()
