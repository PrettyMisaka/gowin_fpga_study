import cv2
import socket
import numpy as np
import sys

# Set up UDP socket
UDP_IP = "127.0.0.1"
UDP_PORT = 5005
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)

# Set up video capture
cap = cv2.VideoCapture(0)

cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1920)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 1080)

cv2.namedWindow("window", cv2.WINDOW_NORMAL)

while True:
    # Capture a frame from the video stream
    ret, frame = cap.read()

    # Compress the frame to JPEG format
    encode_param = [int(cv2.IMWRITE_JPEG_QUALITY), 100]
    _, img_encoded = cv2.imencode('.jpg', frame, encode_param)

    height, width, _ = frame.shape

    # Send the compressed frame over UDP
    print(len(img_encoded),'|',sys.getsizeof(frame))
    sock.sendto(img_encoded, (UDP_IP, UDP_PORT))

    # Display the frame
    cv2.imshow('window', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

# Release the resources
cap.release()
cv2.destroyAllWindows()
sock.close()
