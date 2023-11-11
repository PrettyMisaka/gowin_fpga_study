import sys
import time
from PySide2.QtCore import QTimer, QSize
from PySide2.QtGui import QImage, QPixmap
from PySide2.QtWidgets import QWidget, QLabel, QPushButton, QLineEdit, QVBoxLayout, QApplication, QGridLayout, QMessageBox
from PySide2.QtWebChannel import *
from PySide2.QtUiTools import QUiLoader

import torch
from pathlib import Path
from models.experimental import attempt_load
from models.common       import DetectMultiBackend
from utils.general       import non_max_suppression, scale_coords
from utils.torch_utils   import time_sync
from utils.plots         import Annotator, colors, save_one_box
from utils.augmentations import (Albumentations, augment_hsv, classify_albumentations, classify_transforms, copy_paste,
                                 letterbox, mixup, random_perspective)

import queue
import socket
import threading
import inspect
import ctypes
import cv2
import numpy as np

#yolov5 param
conf_thres = 0.25
iou_thres = 0.45
max_det = 1000
classes = None
agnostic_nms = False
augment = False
save_img = False
save_crop = False
hide_labels = False
hide_conf = False
line_thickness = 3

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
        self.yolov5 = False
        self.record = False

        self.img_save_cnt = 0

        self.queue = queue.Queue()
        self.socket = None
        self.t_udp = None
        self.t_img = None
        self.fourcc = cv2.VideoWriter_fourcc(*'XVID')
        self.out = None

        self.setBtnEnable(False)

        self.stride = None
        self.model  = None 
        self.device = None 
        self.names  = None 
        self.pt     = None
        FILE = Path(__file__).resolve()
        self.ROOT = FILE.parents[0]  # YOLOv5 root directory

        self.record_state = False

    def yolov5LoadModule(self):
        device = torch.device('cuda:0')
        # model = attempt_load(weights='yolov5s.pt', device='cuda:0')
        data=self.ROOT / 'data/coco128.yaml',  # dataset.yaml path
        print(self.ROOT)
        dnn=False,  # use OpenCV DNN for ONNX inference
        half=False,  # use FP16 half-precision inference
        model = DetectMultiBackend(weights=self.ROOT/'yolov5s.pt', device=device, dnn=dnn, data=data, fp16=False)
        stride, names, pt = model.stride, model.names, model.pt
        imgsz = [640,640]  # check image size
        model.warmup(imgsz=(1 if pt else 1, 3, *imgsz))  # warmup
        self.stride = stride 
        self.model  = model  
        self.device = device 
        self.names  = names  
        self.pt     = pt

    def yolov5HandleImg(self,im_bgr):
        
        # Read frame from video capture
        # ret, frame = cap.read()
        # im = cv2.imread(self.ROOT/'data\images\\bus.jpg')
        # Convert frame to PyTorch tensor
        im0s = im_bgr#bgr
        im = cv2.cvtColor(im_bgr, cv2.COLOR_BGR2RGB)

        im = letterbox(im, (640, 640), stride=self.stride, auto=self.pt)[0]
        im = im.transpose((2, 0, 1))[::-1]  # HWC to CHW, BGR to RGB
        im = np.ascontiguousarray(im)

        im = torch.from_numpy(im).to(self.device)
        im = im.half() if self.model.fp16 else im.float()  # uint8 to fp16/32
        im /= 255  # 0 - 255 to 0.0 - 1.0
        if len(im.shape) == 3:
            im = im[None]  # expand for batch dim

        # Inference
        pred = self.model(im, augment=augment, visualize=False)

        # NMS
        pred = non_max_suppression(pred, conf_thres, iou_thres, classes, agnostic_nms, max_det=max_det)

        # Add bbox to image
        for i, det in enumerate(pred):
            p, im0, frame = '0', im0s.copy(), 0
            gn = torch.tensor(im0.shape)[[1, 0, 1, 0]]  # normalization gain whwh
            imc = im0.copy() if save_crop else im0  # for save_crop
            annotator = Annotator(im0, line_width=line_thickness, example=str(self.names))
            if len(det):
                # Rescale boxes from img_size to im0 size
                det[:, :4] = scale_coords(im.shape[2:], det[:, :4], im0.shape).round()
                for *xyxy, conf, cls in reversed(det):
                    view_img = True
                    if save_img or save_crop or view_img:  # Add bbox to image
                        c = int(cls)  # integer class
                        label = None if hide_labels else (self.names[c] if hide_conf else f'{self.names[c]} {conf:.2f}')
                        annotator.box_label(xyxy, label, color=colors(c, True))
            im0 = annotator.result()
            return im0
            cv2.imshow('frame', im0)

    def updata_fps(self,fps):
        self.ui.o_fps.setText(fps)

    def update_frame(self,img):
        if self.denoise:
            img = cv2.medianBlur(img,5)
        if self.yolov5:
            img = self.yolov5HandleImg(img)
            # self.queue.queue.clear()
        self.img = img
        self.ui.o_pixel.setText(str(img.shape[1])+'x'+str(img.shape[0]))
        # print(img.shape[1], img.shape[0], img.strides[0])
        img = cv2.cvtColor(img,cv2.COLOR_BGR2RGB)
        img = cv2.resize(img, (640,480))
        if self.record:
            img_record = cv2.cvtColor(img,cv2.COLOR_RGB2BGR)
            self.out.write(img_record)
        elif self.record_state:
            self.out.release()
            self.record_state = False
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
        if self.yolov5:
            self.yolov5 = False
            self.ui.check_recognition.setChecked(False)
        else:
            if self.model == None :
                self.yolov5LoadModule()
            self.yolov5 = True
            self.ui.check_recognition.setChecked(True)

    def recordFun(self):
        if self.record:
            self.record = False
            self.ui.check_record.setChecked(False)
            self.record_state = True
        else:
            self.ui.check_record.setChecked(True)
            # tmp = '../output.avi'
            self.out = cv2.VideoWriter('output.avi', self.fourcc, 20.0, (640,480))
            self.record = True

    def saveImg(self):
        self.ui.check_capture.setChecked(True)
        tmp = "../output/img_"+str(self.img_save_cnt)+".jpg"
        cv2.imwrite(self.ROOT/tmp, self.img)
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
