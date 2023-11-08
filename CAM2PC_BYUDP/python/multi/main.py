# import utils.threadUtil as threadUtil
import queue
import socket
# import utils.logUtil
import threading
import cv2
import numpy as np
import threading
import time
import inspect
import ctypes
import io
from PIL import Image as pilImage
import warnings
class UdpService_Multi:
    """多线程调用UDP服务时使用UdpService_Multi"""
    def __init__(self, host:str, port:int, queue = None, use_queue = False, bufsize=1500):
        '''
        多线程调用初始化
        :param host: 主机地址 都是接受者的地址
        :param port: 端口 都是接受者的地址端口
        :param queue: 多线程消息队列
        :param use_queue: 是否使用多线程消息队列
        :param bufsize: 消息大小，默认 1024
        '''
        # super(UdpService, self).__init__()
        self.host = host  # 主机地址 都是接受者的地址
        self.port = port  # 端口 都是接受者的地址端口
        self.queue = queue  # 多线程消息队列
        self.use_queue = use_queue  # 是否使用多线程消息队列
        self.bufsize = bufsize  # 消息大小，默认 1024

    def receiver_start(self) -> str or queue:
        """使用UDP协议接收数据，不保证数据是否全被接收！"""
        # 指定使用的协议
        receiver = socket.socket(type=socket.SOCK_DGRAM)
        receiver.bind((self.host,self.port))  # 接收程序的服务地址
        while True:
            # 接收消息
            data, addr = receiver.recvfrom(self.bufsize)  # 设置消息长度 int
            # msg = data.decode('utf8')
            if self.use_queue:
                # 如果使用多线程消息队列传输消息
                if self.queue is None:
                    # 如果使用多线程消息队列但是并未将目标队列传入方法
                    # 抛出异常
                    print('err')
                    # utils.logUtil.LogSys.show_error("请设置多线程消息队列！！！")
                # 如果使用 多线程消息队列
                self.queue.put(data)  # 消息队列放入接收到的信息
                # self.queue.put(msg)  # 消息队列放入接收到的信息
                # print(self.queue.get())
            else:
                # 如果不使用多线程消息队列
                # return msg
                return data

    def send_start(self, msg_queue:queue) -> None:
        """使用UDP协议发送数据，不保证数据能全被送到"""
        # 指定使用的协议
        sender = socket.socket(type=socket.SOCK_DGRAM)
        receiver_addr = (self.host, self.port)  # 接收程序的地址
        while True:
            # 发送消息
            send_msg = msg_queue.get()  # 从消息队列拿数据
            msg = send_msg.strip()
            sender.sendto(msg.encode('utf8'), receiver_addr)


class SendNoLoop:
    """发送消息，但不使用多线程"""
    def __init__(self, host:str, port:int, queue = None, use_queue = False, bufsize=1600):
        # super(UdpService, self).__init__()
        self.host = host  # 主机地址 都是接受者的地址
        self.port = port  # 端口 都是接受者的地址端口
        self.queue = queue  # 多线程消息队列 用于
        self.use_queue = use_queue  # 是否使用多线程消息队列
        self.bufsize = bufsize  # 消息大小，默认 1024
        # 指定使用的协议
        sender = socket.socket(type=socket.SOCK_DGRAM)
        receiver_addr = (self.host, self.port)  # 接收程序的地址
        self.sender = sender
        self.receiver_addr = receiver_addr

    def send_start(self, msg:str) -> None:
        """使用UDP协议发送数据，不保证数据能全被送到"""
        self.sender.sendto(msg.encode('utf8'), self.receiver_addr)

def getRank(data):
    rank = (data[0]%16)*16 + data[1]//16
    return rank
def _async_raise(tid, exctype):
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
def stop_thread(thread):
    _async_raise(thread.ident, SystemExit)

def main():
    host = "192.168.15.15"  # 设置 host 地址
    port = 11451  # 设置端口号
    msg_queue = queue.Queue()  # 设置消息队列
    service = UdpService_Multi(host=host,port=port,queue=msg_queue,use_queue=True)  # 初始化
    t = threading.Thread(target=service.receiver_start)
    t.start()
    # threadUtil.MyThread("UDP Server",service.receiver_start)  # 以子线程启动 UDP 接收服务
    print("12")
    img_data = b''
    rank = 0;
    cv2.namedWindow("window", cv2.WINDOW_NORMAL)
    error = 0
    cnt = 0
    time_start = time.time()
    msg_queue.queue.clear()  # 从消息队列读取信息
    last_image = None
    image_loading = 0
    while True:
        data = msg_queue.get()  # 从消息队列读取信息
        # print("main",getRank(data))
        frame_rank = getRank(data[0:3])
        end_state = (data[0]//16 == 8)
        # img_data = img_data + data[2:]
        # print(frame_rank,end=',')
        if(end_state):
            pass
            # print('\n')
        #     img_data = b''
        # if cv2.waitKey(1) & 0xFF == ord('q'):
        #     break
        # continue
        if(frame_rank == 0):
            img_data = data[2:]
            error = 0
            rank = 0
        elif(~error and (end_state) and frame_rank == rank + 1):
            # print('down')
            img_data = img_data + data[2:]
            jpeg_array = np.frombuffer(img_data, dtype=np.uint8)
            # try:
            image = cv2.imdecode(jpeg_array, cv2.IMREAD_COLOR)
            cnt =cnt + 1
            cv2.imshow('window', image)
            # height, width, channels = image.shape
            # print(f'图像的分辨率为 {width}x{height} 像素')
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        elif(~error and frame_rank == 1 + rank):
            rank = frame_rank
            img_data = img_data + data[2:]
        else:
            error = 1
        time_tmp = time.time()
        if(time_tmp - time_start > 1):
            time_start = time_tmp
            print(cnt)
            cnt = 0
            msg_queue.queue.clear()  # 从消息队列读取信息
    stop_thread(t)
    # t._stop()  # join
    cv2.destroyAllWindows()


if __name__ == '__main__':
    main()