#!/usr/bin/python
# -*- coding: UTF-8 -*-
import argparse
import logging
import subprocess


def image_ls_tags():
    """docker image ls ---> list imgage TAGs"""

    imagesTagList = []
    process = subprocess.Popen(["docker", "image", "ls"], stdout=subprocess.PIPE)
    while True:
        output = process.stdout.readline()
        if process.poll() == 0:
            break
        if output:
            text = output.strip().decode()
            if text.find("lab602") != -1:
                text = list(filter(None, text.split(" ")))
                imagesTagList.append(text[1])
    return imagesTagList


def ps_ap():
    """docker ps -ap ---> list container ID"""

    containerIDList = []
    process = subprocess.Popen(["docker", "ps", "-aq"], stdout=subprocess.PIPE)
    while True:
        output = process.stdout.readline()
        if process.poll() == 0:
            break
        if output:
            containerIDList.append(output.strip().decode())
    return containerIDList


def container_names():
    """docker ps --format "{{.Names}}" ---> list container name"""

    container_nameList = []
    process = subprocess.Popen(
        ["docker", "ps", "--format", "{{.Names}}"], stdout=subprocess.PIPE
    )
    while True:
        output = process.stdout.readline()
        if process.poll() == 0:
            break
        if output:
            container_nameList.append(output.strip().decode())
    return container_nameList


def container_stop_id(containerID):
    """docker container stop id ---> stop container with id"""

    process = subprocess.Popen(["docker", "stop", containerID], stdout=subprocess.PIPE)
    while True:
        output = process.stdout.readline()
        if process.poll() == 0:
            break
        if output:
            pass


def container_rm_id(containerID):
    """docker container rm id ---> remove container with id"""

    process = subprocess.Popen(["docker", "rm", containerID], stdout=subprocess.PIPE)
    while True:
        output = process.stdout.readline()
        if process.poll() == 0:
            break
        if output:
            pass


def container_port_id(containerID):
    """docker container port id ---> list container port"""

    portList = []
    process = subprocess.Popen(
        ["docker", "container", "port", containerID], stdout=subprocess.PIPE
    )
    while True:
        output = process.stdout.readline()
        if process.poll() == 0:
            break
        if output:
            portList.append(output.strip().decode().split(":")[1])
    return portList


def make_clean():
    """make clean ---> clean the build files"""

    process = subprocess.Popen(["make", "clean"], stdout=subprocess.PIPE)
    while True:
        output = process.stdout.readline()
        if process.poll() == 0:
            break
        if output:
            logging.info(output.strip().decode())


def make_build():
    """make build ---> build files"""

    process = subprocess.Popen(["make", "build"], stdout=subprocess.PIPE)
    while True:
        output = process.stdout.readline()
        if process.poll() == 0:
            break
        if output:
            logging.info(output.strip().decode())


def make_run():
    """make run ---> run container"""

    process = subprocess.Popen(["make", "run"], stdout=subprocess.PIPE)
    for _ in range(30):
        output = process.stdout.readline()
        if output:
            logging.info(output.strip().decode())
    process.kill()


def chmod_x(filename):
    """docker container port id ---> list container port"""

    subprocess.Popen(["chmod", "+x", filename], stdout=subprocess.PIPE)


def docker_images_f_dangling_q():
    """docker images -f 'dangling=true' -q ---> list none tag images"""

    noneList = []
    process = subprocess.Popen(
        ["docker", "images", "-f", "dangling=true", "-q"], stdout=subprocess.PIPE
    )
    while True:
        output = process.stdout.readline()
        if process.poll() == 0:
            break
        if output:
            noneList.append(output.strip().decode())
    return noneList


def deleteAll():
    # docker rmi $(docker images -f 'dangling=true' -q)
    noneList = docker_images_f_dangling_q()
    for i in noneList:
        process = subprocess.Popen(["docker", "rmi", i], stdout=subprocess.PIPE)
        while True:
            output = process.stdout.readline()
            if process.poll() == 0:
                break
            if output:
                logging.info(output.strip().decode())


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "--delete_all_none_images",
        help="delete all name is none images",
        action="store_true",
    )

    args = parser.parse_args()

    if args.d:
        deleteAll()


# To delete all containers including its volumes use,
# docker rm -vf $(docker ps -a -q)

# To delete all the images,
# docker rmi -f $(docker images -a -q)
