import sys
import time
from PySide2.QtCore import QTimer, QSize
from PySide2.QtGui import QImage, QPixmap
from PySide2.QtWidgets import QWidget, QLabel, QPushButton, QLineEdit, QVBoxLayout, QApplication, QGridLayout, QMessageBox
from PySide2.QtWebChannel import *
from PySide2.QtUiTools import QUiLoader

import queue
import socket
import threading
import inspect
import ctypes
import cv2
import numpy as np

def creatUDPrxThreading(socket,queue,bufsize=1500):
    def queueStart():
        while True:
            data, addr = socket.recvfrom(bufsize)  # 设置消息长度 int
            queue.put(data)  # 消息队列放入接收到的信息
    thread = threading.Thread(target=queueStart)
    thread.start()
    return thread

def creatIMGhandleThreading(queue,imgUPDFun,fpsUPDFun):
    def handleUDPFun():
        rank = 0
        error = 0
        cnt = 0
        time_start = time.time()
        queue.queue.clear()  # 从消息队列读取信息
        while True:
            data = queue.get()  # 从消息队列读取信息
            frame_rank = (data[0]%16)*16 + data[1]//16
            end_state = (data[0]//16 == 8)
            if(end_state):
                pass
            if(frame_rank == 0):
                img_data = data[2:]
                error = 0
                rank = 0
            elif(~error and (end_state) and frame_rank == rank + 1):
                img_data = img_data + data[2:]
                jpeg_array = np.frombuffer(img_data, dtype=np.uint8)
                image = cv2.imdecode(jpeg_array, cv2.IMREAD_COLOR)
                cnt =cnt + 1
                imgUPDFun(image)
                time.sleep(0.001)
            elif(~error and frame_rank == 1 + rank):
                rank = frame_rank
                img_data = img_data + data[2:]
            else:
                error = 1
            time_tmp = time.time()
            if(time_tmp - time_start > 1):
                time_start = time_tmp
                fpsUPDFun(str(cnt))
                cnt = 0
                queue.queue.clear()  # 从消息队列读取信息
    thread = threading.Thread(target=handleUDPFun)
    thread.start()
    return thread

def stopThread(thread):
    tid = thread.ident
    exctype = SystemExit
    """raises the exception, performs cleanup if needed"""
    tid = ctypes.c_long(tid)
    if not inspect.isclass(exctype):
        exctype = type(exctype)
    res = ctypes.pythonapi.PyThreadState_SetAsyncExc(tid, ctypes.py_object(exctype))
    if res == 0:
        raise ValueError("invalid thread id")
    elif res != 1:
        # """if it returns a number greater than one, you're in trouble,
        # and you should call it again with exc=NULL to revert the effect"""
        ctypes.pythonapi.PyThreadState_SetAsyncExc(tid, None)
        raise SystemError("PyThreadState_SetAsyncExc failed")

class Stats:
    def __init__(self):
        # 比如 self.ui.button , self.ui.textEdit
        self.ui = QUiLoader().load('CAM2PC_BYUDP/app/pyside2.ui')

        self.ui.btn_start.clicked.connect(self.btn_start_ctrl)
        self.ui.btn_denoise.clicked.connect(self.denoiseFun)
        self.ui.btn_recognition.clicked.connect(self.imgRecognitionFun)
        self.ui.btn_capture.clicked.connect(self.saveImg)
        self.ui.btn_record.clicked.connect(self.recordFun)

        self.state = 0
        self.denoise = False
        self.img_ai = False
        self.record = False

        self.img_save_cnt = 0

        self.queue = queue.Queue()
        self.socket = None
        self.t_udp = None
        self.t_img = None
        self.fourcc = cv2.VideoWriter_fourcc(*'XVID')
        self.out = None

        self.setBtnEnable(False)

    def updata_fps(self,fps):
        self.ui.o_fps.setText(fps)

    def update_frame(self,img):
        if self.denoise:
            img = cv2.medianBlur(img,5)
        self.img = img
        self.ui.o_pixel.setText(str(img.shape[1])+'x'+str(img.shape[0]))
        # print(img.shape[1], img.shape[0], img.strides[0])
        img = cv2.resize(img, (640,480))
        img = cv2.cvtColor(img,cv2.COLOR_BGR2RGB)
        if self.record:
            img_record = cv2.cvtColor(img,cv2.COLOR_RGB2BGR)
            self.out.write(img_record)
        image = QImage(img, img.shape[1], img.shape[0], img.strides[0], QImage.Format_RGB888)
        self.ui.img.setPixmap(QPixmap.fromImage(image))
        self.ui.check_capture.setChecked(False)

    def denoiseFun(self):
        if self.denoise:
            self.denoise = False
            self.ui.check_denoise.setChecked(False)
        else:
            self.denoise = True
            self.ui.check_denoise.setChecked(True)

    def imgRecognitionFun(self):
        if self.img_ai:
            self.img_ai = False
            self.ui.check_recognition.setChecked(False)
        else:
            self.img_ai = True
            self.ui.check_recognition.setChecked(True)

    def recordFun(self):
        if self.record:
            self.record = False
            self.ui.check_record.setChecked(False)
            self.out.release()
        else:
            self.ui.check_record.setChecked(True)
            self.out = cv2.VideoWriter('output.avi', self.fourcc, 20.0, (640,480))
            self.record = True

    def saveImg(self):
        self.ui.check_capture.setChecked(True)
        cv2.imwrite("output/img_"+str(self.img_save_cnt)+".jpg", self.img)
        self.img_save_cnt = self.img_save_cnt + 1

    def setBtnEnable(self,val):
        self.ui.btn_denoise.setEnabled(val)
        self.ui.btn_recognition.setEnabled(val)
        self.ui.btn_record.setEnabled(val)
        self.ui.btn_capture.setEnabled(val)

    def btn_start_ctrl(self):
        address = self.ui.i_src_ip.text()
        port = self.ui.i_port.text()
        if self.state:
            self.state = 0
            self.ui.btn_start.setText('start')
            self.ui.i_src_ip.setEnabled(True)
            self.ui.i_port.setEnabled(True)
            self.setBtnEnable(False)
            stopThread(self.t_udp)
            self.t_udp = None
            stopThread(self.t_img)
            self.t_img = None
            self.socket.close()
        else:
            self.state = 1
            self.ui.btn_start.setText('close')
            self.ui.i_src_ip.setEnabled(False)
            self.ui.i_port.setEnabled(False)
            self.setBtnEnable(True)
            self.socket = socket.socket(type=socket.SOCK_DGRAM)
            self.socket.bind((address,int(port)))  # 接收程序的服务地址
            self.t_udp = creatUDPrxThreading( socket=self.socket, queue=self.queue, bufsize=1500)
            self.t_img = creatIMGhandleThreading( queue=self.queue, imgUPDFun=self.update_frame, fpsUPDFun=self.updata_fps)

        print(self.state,address,port)
        time.sleep(0.1)

app = QApplication(sys.argv)
stats = Stats()

def on_exit():
    # 在程序退出前打印消息
    print("Program exited")
    if stats.t_udp != None :
        stopThread(stats.t_udp)
    if stats.t_img != None :
        stopThread(stats.t_img)
    stats.queue.queue.clear()
    if stats.socket != None :
        stats.socket.close()

if __name__ == "__main__":
    stats.ui.show()
    app.aboutToQuit.connect(on_exit)
    sys.exit(app.exec_())
