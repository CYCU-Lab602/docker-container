#!/usr/bin/env python3
# -*- coding:utf-8 -*-

"""
runtime = 沒有包含cuda的nvcc
devel = 有包含cuda的nvcc
"""

support_images = [
    "nvidia/cuda:11.4.3-cudnn8-devel-ubuntu20.04",
    "nvidia/cuda:12.3.1-devel-ubuntu20.04",
]
