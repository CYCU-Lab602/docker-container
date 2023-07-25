#!/usr/bin/python
# -*- coding: UTF-8 -*-
from datetime import datetime
import configparser
import logging
import random
import string
import secrets
import docker
import shutil
import os
import sys
from images.version import support_images
import time
import subprocess

file_handler = logging.FileHandler('vnc/log/{}.log'.format(datetime.today().strftime('%Y-%m-%d-%H:%M:%S')))
console_handler = logging.StreamHandler(sys.stdout)
console_handler.setLevel(logging.INFO)

logging.basicConfig(
    level=logging.INFO,
    # format='(asctime)s.%(msecs)03d %(levelname)s %(module)s - %(funcName)s: %(message)s',
    format='%(message)s',
    datefmt='%Y-%m-%d %H:%M:%S',
    handlers=[
        file_handler,
        console_handler
    ]
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
        # randomPort = random.randrange(49152, 65535, 4)
        randomPort = random.randrange(52360, 55560, 4)
        logging.debug(randomPort)
        try:
            logging.debug(usingPortList.index(port))
        except:
            break
    return randomPort


def makePasswordWith(mode):
    alphabet = string.ascii_letters + string.digits
    if mode == 4:
        password = ''.join(secrets.choice(alphabet) for i in range(4))
    elif mode == 16:
        password = ''.join(secrets.choice(alphabet) for i in range(16))
    return password


def fileKeeper():
    os.remove('Makefile')
    os.remove('Dockerfile.j2')
    os.remove('rootfs/startup.sh')
    shutil.copy2('vnc/data/source/Makefile', 'Makefile')
    shutil.copy2('vnc/data/source/Dockerfile.j2', 'Dockerfile.j2')
    shutil.copy2('vnc/data/source/startup.sh', 'rootfs/startup.sh')
    docker.chmod_x(filename='rootfs/startup.sh')


def customFiles(infodict, isBuild=False):
    lines = []
    unusedPort = findUnusedPort()
    with open('vnc/data/modified/Makefile', 'r', encoding='utf8') as f:
        for i in f.readlines():
            if i.find('REPO  ?= ') != -1:
                lines.append('REPO  ?= {}\n'.format(infodict['repo']))
            elif i.find('TAG   ?= ') != -1:
                lines.append('TAG   ?= {}\n'.format(infodict['tag']))
            elif i.find('IMAGE ?= ') != -1:
                lines.append('IMAGE ?= {}\n'.format(infodict['image']))
            elif i.find('OPENCV ?= ') != -1:
                lines.append('OPENCV ?= {}\n'.format(infodict['openCV']))
            elif i.find('GPUS ?= ') != -1:
                lines.append('GPUS ?= {}\n'.format(infodict['GPUS']))
            elif i.find('PORT80 ?= ') != -1:
                lines.append('PORT80 ?= {}\n'.format(unusedPort))
            elif i.find('PORT443 ?= ') != -1:
                lines.append('PORT443 ?= {}\n'.format(unusedPort+2))
            elif i.find('PORT22 ?= ') != -1:
                lines.append('PORT22 ?= {}\n'.format(unusedPort+1))
            elif i.find('PORT6006 ?= ') != -1:
                lines.append('PORT6006 ?= {}\n'.format(unusedPort+3))
            elif i.find('USERSNAME ?= ') != -1:
                lines.append('USERSNAME ?= {}\n'.format('lab602.{}'.format(infodict['StudentID'])))
            elif i.find('USERSPSWD ?= ') != -1:
                lines.append('USERSPSWD ?= {}\n'.format(infodict['UserPassword']))
            elif i.find('WEBSITEPSWD ?= ') != -1:
                lines.append('WEBSITEPSWD ?= {}\n'.format(infodict['WebsitePassword']))
            elif i.find('ROOTPSWD ?= ') != -1:
                lines.append('ROOTPSWD ?= {}\n'.format(infodict['RootPassword']))
            elif i.find('CONTAINERNAME ?= ') != -1:
                lines.append('CONTAINERNAME ?= {}\n'.format(infodict['StudentID']))
            else:
                lines.append(i)

    fileKeeper()
    shutil.copy2('vnc/data/modified/Dockerfile.j2', 'Dockerfile.j2')
    shutil.copy2('vnc/data/modified/startup.sh', 'rootfs/startup.sh')
    docker.chmod_x(filename='rootfs/startup.sh')
    
    with open('Makefile', 'w', encoding='utf8') as f:
        f.writelines(lines)
    docker.make_clean()
    
    if isBuild:
        docker.make_build()
    docker.make_run()
    
    fileKeeper()

    logging.info('')
    logging.info('----------CONTAINER INFO----------')
    logging.info('- User Name = {}'.format('lab602.{}'.format(infodict['StudentID'])))
    logging.info('- User Password = {}'.format(infodict['UserPassword']))
    logging.info('- Website Password = {}'.format(infodict['WebsitePassword']))
    logging.info('- CONTAINER Name = {}'.format(infodict['StudentID']))
    logging.info('- Port 80 = {}'.format(unusedPort))
    logging.info('- Port 22 = {}'.format(unusedPort+1))
    logging.info('- Port 443 = {}'.format(unusedPort+2))
    logging.info('- Port 6006 = {}'.format(unusedPort+3))
    logging.info('----------------------------------')


def main():
    # welcome message
    logging.info('''
██╗░░░░░░█████╗░██████╗░░█████╗░░█████╗░██████╗░
██║░░░░░██╔══██╗██╔══██╗██╔═══╝░██╔══██╗╚════██╗
██║░░░░░███████║██████╦╝██████╗░██║░░██║░░███╔═╝
██║░░░░░██╔══██║██╔══██╗██╔══██╗██║░░██║██╔══╝░░
███████╗██║░░██║██████╦╝╚█████╔╝╚█████╔╝███████╗
╚══════╝╚═╝░░╚═╝╚═════╝░░╚════╝░░╚════╝░╚══════╝

░█████╗░░█████╗░███╗░░██╗████████╗░█████╗░██╗███╗░░██╗███████╗██████╗░
██╔══██╗██╔══██╗████╗░██║╚══██╔══╝██╔══██╗██║████╗░██║██╔════╝██╔══██╗
██║░░╚═╝██║░░██║██╔██╗██║░░░██║░░░███████║██║██╔██╗██║█████╗░░██████╔╝
██║░░██╗██║░░██║██║╚████║░░░██║░░░██╔══██║██║██║╚████║██╔══╝░░██╔══██╗
╚█████╔╝╚█████╔╝██║░╚███║░░░██║░░░██║░░██║██║██║░╚███║███████╗██║░░██║
░╚════╝░░╚════╝░╚═╝░░╚══╝░░░╚═╝░░░╚═╝░░╚═╝╚═╝╚═╝░░╚══╝╚══════╝╚═╝░░╚═╝

░██████╗░█████╗░██████╗░██╗██████╗░████████╗
██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝
╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░
░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░
██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░
╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░
    ''')

    while True:
        infoDict = {'repo': 'lab602',
                    'tag': '',
                    'image': '',
                    'openCV': '',
                    'GPUS': '',
                    'StudentID': '',
                    'UserPassword': '',
                    'RootPassword': '',
                    'WebsitePassword': ''}
        configParser = configparser.RawConfigParser()   
        configFilePath = 'vnc/config'
        configParser.read(configFilePath)
        infoDict['RootPassword'] = configParser.get('config', 'RootPassword')

        # log container image list
        logging.info('\n------------------------Supported Images-------------------------')
        for index, image in enumerate(support_images):
            logging.info('|\t {}: {}\t\t|'.format(index, image))
        logging.info('-----------------------------------------------------------------')

        while True:
            cudaVersion = input('\n(1) Choose your container image: ')

            if int(cudaVersion) >= len(support_images):
                logging.info('Error index!')
                break
            infoDict['tag'] = support_images[int(cudaVersion)].split(':')[1]
            infoDict['image'] = support_images[int(cudaVersion)]
            print(infoDict)

            while True:
                smiOutput = subprocess.run(['nvidia-smi', '-L'], stdout=subprocess.PIPE).stdout.decode('utf-8').split('\n')
                logging.info('\n-------------------------Supported GPUs--------------------------')
                logging.info('|\t {}\t\t\t|'.format(smiOutput[0].split('(')[0]))
                logging.info('|\t {}\t\t\t|'.format(smiOutput[1].split('(')[0]))
                logging.info('-----------------------------------------------------------------')

                while True:
                    gpusAns = input('\n(2) Choose the GPU(s) you want to use: ')
                    if (len(gpusAns)>int((len(smiOutput)-2)*2+1)):
                        logging.info('Error index!')
                        break
                    else:
                        infoDict['GPUS'] = gpusAns
            
                    while True:
                        studentID = input('\n(3) Enter your container\'s name: ')
                        infoDict['StudentID'] = studentID

                        while True: 
                            container_names = docker.container_names()

                            if any(infoDict['StudentID'] in x for x in container_names):
                                isDeleted = input('\nFound duplicate container, stop & remove? (y/n) ')
                                if isDeleted == 'y':
                                    docker.container_stop_id(infoDict['StudentID'])
                                    logging.info('Stopped: {}'.format(infoDict['StudentID']))
                                    time.sleep(0.3)
                                    docker.container_rm_id(infoDict['StudentID'])
                                    logging.info('Killed: {}'.format(infoDict['StudentID']))
                                else:
                                    logging.info('Please enter a new container name!\n')
                                    break

                            while True:
                                userPassword = input('\n(4) Enter your ssh password: ')
                                vncPassword = input('\n(5) Enter your vnc password: ')

                                while True:
                                    isPassOK = input('''
(6) Please review your container info:
    - Container name: {}
    - User Password : {}
    - Website password : {}\n
Confirm? (y/n) '''.format(studentID, userPassword, vncPassword))

                                    if isPassOK == 'y':
                                        infoDict['UserPassword'] = userPassword
                                        infoDict['WebsitePassword'] = vncPassword
                                        if any(infoDict['tag'] in x for x in docker.image_ls_tags()):
                                            customFiles(infoDict)
                                        else:
                                            customFiles(infoDict, isBuild=True)
                                        exit(0)
                                    else:
                                        break

if __name__ == '__main__':
    main()
