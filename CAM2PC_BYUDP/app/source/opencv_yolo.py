import cv2
import torch
import numpy as np
from pathlib import Path
from models.experimental import attempt_load
from models.common import DetectMultiBackend
from utils.general import non_max_suppression, scale_coords
from utils.torch_utils import time_sync
from utils.plots import Annotator, colors, save_one_box
from utils.augmentations import (Albumentations, augment_hsv, classify_albumentations, classify_transforms, copy_paste,
                                 letterbox, mixup, random_perspective)

# Load Yolov5 model
# model = attempt_load(weights='yolov5s.pt', map_location=torch.device('cpu'))
device = torch.device('cuda:0')
# model = attempt_load(weights='yolov5s.pt', device='cuda:0')
FILE = Path(__file__).resolve()
ROOT = FILE.parents[0]  # YOLOv5 root directory
data=ROOT / 'data/coco128.yaml',  # dataset.yaml path
print(ROOT)
dnn=False,  # use OpenCV DNN for ONNX inference
half=False,  # use FP16 half-precision inference
model = DetectMultiBackend(weights=ROOT/'yolov5s.pt', device=device, dnn=dnn, data=data, fp16=False)
stride, names, pt = model.stride, model.names, model.pt
imgsz = [640,640]  # check image size
model.warmup(imgsz=(1 if pt else 1, 3, *imgsz))  # warmup

# Set device
# device = torch.device('cuda:0' if torch.cuda.is_available() else 'cpu')

# Set parameters
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

if True:
    # Read frame from video capture
    # ret, frame = cap.read()
    im = cv2.imread(ROOT/'data\images\\bus.jpg')

    # Convert frame to PyTorch tensor
    im0s = im#bgr
    im = cv2.cvtColor(im, cv2.COLOR_BGR2RGB)

    im = letterbox(im, (640, 640), stride=stride, auto=pt)[0]
    im = im.transpose((2, 0, 1))[::-1]  # HWC to CHW, BGR to RGB
    im = np.ascontiguousarray(im)

    im = torch.from_numpy(im).to(device)
    im = im.half() if model.fp16 else im.float()  # uint8 to fp16/32
    im /= 255  # 0 - 255 to 0.0 - 1.0
    if len(im.shape) == 3:
        im = im[None]  # expand for batch dim

    # Inference
    pred = model(im, augment=augment, visualize=False)

    # NMS
    pred = non_max_suppression(pred, conf_thres, iou_thres, classes, agnostic_nms, max_det=max_det)

    # Add bbox to image
    for i, det in enumerate(pred):
        p, im0, frame = '0', im0s.copy(), 0

        # p = Path(p)  # to Path
        # save_path = str(save_dir / p.name)  # im.jpg
        # txt_path = str(save_dir / 'labels' / p.stem) + ('' if dataset.mode == 'image' else f'_{frame}')  # im.txt
        gn = torch.tensor(im0.shape)[[1, 0, 1, 0]]  # normalization gain whwh
        imc = im0.copy() if save_crop else im0  # for save_crop
        annotator = Annotator(im0, line_width=line_thickness, example=str(names))
        if len(det):
            # Rescale boxes from img_size to im0 size
            det[:, :4] = scale_coords(im.shape[2:], det[:, :4], im0.shape).round()

            # Print results
            for c in det[:, -1].unique():
                n = (det[:, -1] == c).sum()  # detections per class

            # Write results
            for *xyxy, conf, cls in reversed(det):
                # if save_txt:  # Write to file
                #     xywh = (xyxy2xywh(torch.tensor(xyxy).view(1, 4)) / gn).view(-1).tolist()  # normalized xywh
                #     line = (cls, *xywh, conf) if save_conf else (cls, *xywh)  # label format
                #     with open(f'{txt_path}.txt', 'a') as f:
                #         f.write(('%g ' * len(line)).rstrip() % line + '\n')
                view_img = True
                if save_img or save_crop or view_img:  # Add bbox to image
                    c = int(cls)  # integer class
                    label = None if hide_labels else (names[c] if hide_conf else f'{names[c]} {conf:.2f}')
                    annotator.box_label(xyxy, label, color=colors(c, True))
        
        im0 = annotator.result()

    # Display image
        cv2.imshow('frame', im0)

    # Exit on 'q' key press
    # if cv2.waitKey(1) & 0xFF == ord('q'):
    #     break

# Release video capture and close window
while True:
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
cv2.destroyAllWindows()
