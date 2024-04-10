# YoloV7 Container Manual
- __Author:__ Guan-Liang Lin
- __Contact:__ noah@c-link.com.tw
- __Date:__ 2024-04-10
## Switch to admin user to gain access to root directory
```bash
admin # ask admin's password from maintainer
```
## Copy your inference video to workstation's data directory
```bash
sudo cp {YOUR_VIDEO} /media/ai/data/v7/yolov7/videos/
```
## Attach to container shell through docker
```bash
docker exec -it -u v7 v7 /usr/bin/fish
```
> make sure to check your working directory using `pwd`, it should be `/home/v7/data/v7/yolov7`
## Run demo.py to inference your video
```bash
python demo.py
```
