#!/usr/bin/env python3
# -*- coding:utf-8 -*-
# Copyright (c) 2021 Lab602 LEE HAO. All rights reserved.

'''
runtime = 沒有包含cuda的nvcc
devel = 有包含cuda的nvcc
'''

support_images = [  'nvidia/cuda:11.4.1-cudnn8-devel-ubuntu18.04',
                    'nvidia/cuda:11.4.1-cudnn8-devel-ubuntu20.04',
                    'nvidia/cuda:11.4.0-cudnn8-devel-ubuntu18.04',
                    'nvidia/cuda:11.4.0-cudnn8-devel-ubuntu20.04',
                    'nvidia/cuda:11.0-cudnn8-devel-ubuntu18.04',
                    'nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04',
                ]
