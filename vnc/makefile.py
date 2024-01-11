#!/usr/bin/python
# -*- coding: UTF-8 -*-
import configparser
import logging
import os
import random
import secrets
import shutil
import string
import subprocess
import sys
import time
from datetime import datetime

import docker
from images.version import support_images

file_handler = logging.FileHandler(
    "vnc/log/{}.log".format(datetime.today().strftime("%Y-%m-%d-%H:%M:%S"))
)
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(logging.INFO)

logging.basicConfig(
    level=logging.INFO,
    # format='(asctime)s.%(msecs)03d %(levelname)s %(module)s - %(funcName)s: %(message)s',
    format="%(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[file_handler, console_handler],
)


logging.getLogger("requests").setLevel(logging.NOTSET)


def findUnusedPort():
    usingPortList = []
    containerIDList = docker.ps_ap()
    for i in containerIDList:
        for port in docker.container_port_id(i):
            logging.debug(port)
            try:
                usingPortList.append(int(port))
            except:
                continue
    logging.debug(usingPortList)
    while True:
        randomPort = random.randrange(52360, 55560, 4)
        logging.debug(randomPort)
        try:
            logging.debug(usingPortList.index(randomPort))
        except:
            break
    return randomPort


def makePasswordWith(mode):
    alphabet = string.ascii_letters + string.digits
    password = ""
    if mode == 4:
        password = "".join(secrets.choice(alphabet) for i in range(4))
    elif mode == 16:
        password = "".join(secrets.choice(alphabet) for i in range(16))
    return password


def fileKeeper():
    os.remove("Makefile")
    os.remove("Dockerfile.j2")
    os.remove("rootfs/startup.sh")
    shutil.copy2("vnc/data/source/Makefile", "Makefile")
    shutil.copy2("vnc/data/source/Dockerfile.j2", "Dockerfile.j2")
    shutil.copy2("vnc/data/source/startup.sh", "rootfs/startup.sh")
    docker.chmod_x(filename="rootfs/startup.sh")


def customFiles(infodict, isBuild=False):
    lines = []
    unusedPort = findUnusedPort()
    with open("vnc/data/modified/Makefile", "r", encoding="utf8") as f:
        for i in f.readlines():
            if i.find("REPO  ?= ") != -1:
                lines.append("REPO  ?= {}\n".format(infodict["repo"]))
            elif i.find("TAG   ?= ") != -1:
                lines.append("TAG   ?= {}\n".format(infodict["tag"]))
            elif i.find("IMAGE ?= ") != -1:
                lines.append("IMAGE ?= {}\n".format(infodict["image"]))
            elif i.find("OPENCV ?= ") != -1:
                lines.append("OPENCV ?= {}\n".format(infodict["openCV"]))
            elif i.find("GPUS ?= ") != -1:
                lines.append("GPUS ?= {}\n".format(infodict["GPUS"]))
            elif i.find("PORT80 ?= ") != -1:
                lines.append("PORT80 ?= {}\n".format(unusedPort))
            elif i.find("PORT443 ?= ") != -1:
                lines.append("PORT443 ?= {}\n".format(unusedPort + 2))
            elif i.find("PORT22 ?= ") != -1:
                lines.append("PORT22 ?= {}\n".format(unusedPort + 1))
            elif i.find("PORT6006 ?= ") != -1:
                lines.append("PORT6006 ?= {}\n".format(unusedPort + 3))
            elif i.find("USERSNAME ?= ") != -1:
                lines.append(
                    "USERSNAME ?= {}\n".format(
                        "lab602.{}".format(infodict["StudentID"])
                    )
                )
            elif i.find("USERSPSWD ?= ") != -1:
                lines.append("USERSPSWD ?= {}\n".format(infodict["UserPassword"]))
            elif i.find("WEBSITEPSWD ?= ") != -1:
                lines.append("WEBSITEPSWD ?= {}\n".format(infodict["WebsitePassword"]))
            elif i.find("ROOTPSWD ?= ") != -1:
                lines.append("ROOTPSWD ?= {}\n".format(infodict["RootPassword"]))
            elif i.find("CONTAINERNAME ?= ") != -1:
                lines.append("CONTAINERNAME ?= {}\n".format(infodict["StudentID"]))
            else:
                lines.append(i)

    fileKeeper()
    shutil.copy2("vnc/data/modified/Dockerfile.j2", "Dockerfile.j2")
    shutil.copy2("vnc/data/modified/startup.sh", "rootfs/startup.sh")
    docker.chmod_x(filename="rootfs/startup.sh")

    with open("Makefile", "w", encoding="utf8") as f:
        f.writelines(lines)
    docker.make_clean()

    if isBuild:
        docker.make_build()
    docker.make_run()

    fileKeeper()

    logging.info("")
    logging.info("----------CONTAINER INFO----------")
    logging.info("- User Name = {}".format("clink.{}".format(infodict["StudentID"])))
    logging.info("- User Password = {}".format(infodict["UserPassword"]))
    logging.info("- Website Password = {}".format(infodict["WebsitePassword"]))
    logging.info("- CONTAINER Name = {}".format(infodict["StudentID"]))
    logging.info("- Port 80 = {}".format(unusedPort))
    logging.info("- Port 22 = {}".format(unusedPort + 1))
    logging.info("- Port 443 = {}".format(unusedPort + 2))
    logging.info("- Port 6006 = {}".format(unusedPort + 3))
    logging.info("----------------------------------")


def main():
    # welcome message
    logging.info(
        """
 .d8888b.         888      8888888 888b    888 888    d8P
d88P  Y88b        888        888   8888b   888 888   d8P
888    888        888        888   88888b  888 888  d8P
888               888        888   888Y88b 888 888d88K
888               888        888   888 Y88b888 8888888b
888    888 888888 888        888   888  Y88888 888  Y88b
Y88b  d88P        888        888   888   Y8888 888   Y88b
 "Y8888P"         88888888 8888888 888    Y888 888    Y88b

8888888b.   .d88888b.   .d8888b.  888    d8P  8888888888 8888888b.
888  "Y88b d88P" "Y88b d88P  Y88b 888   d8P   888        888   Y88b
888    888 888     888 888    888 888  d8P    888        888    888
888    888 888     888 888        888d88K     8888888    888   d88P
888    888 888     888 888        8888888b    888        8888888P"
888    888 888     888 888    888 888  Y88b   888        888 T88b
888  .d88P Y88b. .d88P Y88b  d88P 888   Y88b  888        888  T88b
8888888P"   "Y88888P"   "Y8888P"  888    Y88b 8888888888 888   T88b

 .d8888b.   .d8888b.  8888888b.  8888888 8888888b. 88888888888
d88P  Y88b d88P  Y88b 888   Y88b   888   888   Y88b    888
Y88b.      888    888 888    888   888   888    888    888
 "Y888b.   888        888   d88P   888   888   d88P    888
    "Y88b. 888        8888888P"    888   8888888P"     888
      "888 888    888 888 T88b     888   888           888
Y88b  d88P Y88b  d88P 888  T88b    888   888           888
 "Y8888P"   "Y8888P"  888   T88b 8888888 888           888
    """
    )

    while True:
        infoDict = {
            "repo": "clink",
            "tag": "",
            "image": "",
            "openCV": "",
            "GPUS": "",
            "EmployeeName": "",
            "UserPassword": "",
            "RootPassword": "",
            "WebsitePassword": "",
        }
        configParser = configparser.RawConfigParser()
        configFilePath = "vnc/config"
        configParser.read(configFilePath)
        infoDict["RootPassword"] = configParser.get("config", "RootPassword")

        # log container image list
        logging.info(
            "\n------------------------Supported Images-------------------------"
        )
        for index, image in enumerate(support_images):
            logging.info("|\t {}: {}\t\t|".format(index, image))
        logging.info(
            "-----------------------------------------------------------------"
        )

        while True:
            cudaVersion = input("\n(1) Choose your container image: ")

            if int(cudaVersion) >= len(support_images):
                logging.info("Error index!")
                break
            infoDict["tag"] = support_images[int(cudaVersion)].split(":")[1]
            infoDict["image"] = support_images[int(cudaVersion)]

            while True:
                smiOutput = (
                    subprocess.run(["nvidia-smi", "-L"], stdout=subprocess.PIPE)
                    .stdout.decode("utf-8")
                    .split("\n")
                )
                logging.info(
                    "\n-------------------------Supported GPUs--------------------------"
                )
                for i in range(len(smiOutput) - 1):
                    logging.info("|\t {}\t\t\t|".format(smiOutput[i].split("(")[0]))
                logging.info(
                    "-----------------------------------------------------------------"
                )

                while True:
                    gpusAns = input("\n(2) Choose the GPU(s) you want to use: ")
                    if len(gpusAns) > int((len(smiOutput) - 2) * 2 + 1):
                        logging.info("Error index!")
                        break
                    else:
                        infoDict["GPUS"] = gpusAns

                    while True:
                        employeeName = input("\n(3) Enter your container's name: ")
                        infoDict["EmployeeName"] = employeeName

                        while True:
                            container_names = docker.container_names()

                            if any(
                                infoDict["EmployeeName"] in x for x in container_names
                            ):
                                isDeleted = input(
                                    "\nFound duplicate container, stop & remove? (y/n) "
                                )
                                if isDeleted == "y":
                                    docker.container_stop_id(infoDict["EmployeeName"])
                                    logging.info(
                                        "Stopped: {}".format(infoDict["EmployeeName"])
                                    )
                                    time.sleep(0.3)
                                    docker.container_rm_id(infoDict["EmployeeName"])
                                    logging.info(
                                        "Killed: {}".format(infoDict["EmployeeName"])
                                    )
                                else:
                                    logging.info("Please enter a new container name!\n")
                                    break

                            while True:
                                userPassword = input("\n(4) Enter your ssh password: ")
                                vncPassword = input("\n(5) Enter your vnc password: ")

                                while True:
                                    isPassOK = input(
                                        """
(6) Please review your container info:
    - Container name: {}
    - User Password : {}
    - Website password : {}\n
Confirm? (y/n) """.format(
                                            employeeName, userPassword, vncPassword
                                        )
                                    )

                                    if isPassOK == "y":
                                        infoDict["UserPassword"] = userPassword
                                        infoDict["WebsitePassword"] = vncPassword
                                        if any(
                                            infoDict["tag"] in x
                                            for x in docker.image_ls_tags()
                                        ):
                                            customFiles(infoDict)
                                        else:
                                            customFiles(infoDict, isBuild=True)
                                        exit(0)
                                    else:
                                        break


if __name__ == "__main__":
    main()
