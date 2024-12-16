# C-Link Workstation Container Script
- __Description:__ Set up docker dependencies
- __Author:__ Guan Liang, Lin
- __Contact:__ popshia@gmail.com
- __Date:__ 2024-03-18

# Table of Contents
* [Checkout to clink branch](#checkout-to-clink-branch)
* [Install nvidia drivers](#install-nvidia-drivers)
* [Install docker engine](#install-docker-engine)
* [Setup docker permissions](#setup-docker-permissions)
* [Install nvidia-docker](#install-nvidia-docker)
* [Test](#test)
* [Install VNC](#install-vnc)
* [Make image](#make-image)
* [IP settings](#ip-settings)
* [File specifications](#file-specifications)

## Checkout to `clink` branch
```bash
git checkout clink
```
## Install nvidia drivers
```bash
# check
sudo add-apt-repository -y ppa:graphics-drivers/ppa
sudo apt update
sudo apt install -y ubuntu-drivers-common
# check device drivers
ubuntu-drivers devices
# auto install drivers
ubuntu-drivers autoinstall
# or choose the recommend driver
sudo apt install -y (nvidia-430)
# reboot to take effects
sudo reboot
```
## Install docker engine
```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
# Install the latest version
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Verify installation
sudo docker run hello-world
```
## Setup docker permissions
```bash
sudo groupadd docker
sudo gpasswd -a $USER docker
sudo reboot
```
> [Docker reference](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)
## Install nvidia-docker
```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
sudo nvidia-ctk runtime configure --runtime=containerd
sudo systemctl restart containerd
sudo nvidia-ctk runtime configure --runtime=crio
sudo systemctl restart crio
```
> [nvidia-docker reference]( https://github.com/NVIDIA/nvidia-docker )

## Test
```bash
docker run --rm --runtime=nvidia --gpus all ubuntu nvidia-smi
```
## Install VNC
```bash
git submodule init; git submodule update
```
## Make image
> Tweak the paths in [Makefile](./Makefile).
```bash
sudo apt install -y make
python3 vnc/makefile.py
```
## Install `ctop` to monitor container usage
```bash
sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop
```
