obj-m += mpu.o
mpu-objs := src/mpu_drv.o src/mpu_syscall_hook.o src/mpu_ioctl.o

# 构建时使用传入的 KVERSION，不依赖 uname -r（容器内 uname -r 为宿主机内核）
# 示例: make KVERSION=5.4.0-150-generic
KVERSION ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVERSION)/build
PWD := $(shell pwd)

REGISTRY := ghcr.io
REGISTRY_PATH := dynamia-ai/mpu
IMAGE_VERSION  ?= $(shell git describe --tags --dirty 2> /dev/null || git rev-parse --short HEAD)

default:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

install:
	insmod mpu.ko
	echo mpu > /etc/modules-load.d/matpool-mpu.conf

uninstall:
	rmmod mpu.ko
	rm /etc/modules-load.d/matpool-mpu.conf

# 完整镜像（含多阶段预编译 build/<kver>/mpu.ko），默认基础镜像 ubuntu:22.04
images:
	docker build -t $(REGISTRY)/$(REGISTRY_PATH):$(IMAGE_VERSION) -f Dockerfile .

# 按不同基础镜像构建并打上对应标签（如 :$(IMAGE_VERSION)-ubuntu20.04）
images-ubuntu20.04:
	docker build --build-arg BASE_IMAGE=ubuntu:20.04 -t $(REGISTRY)/$(REGISTRY_PATH):$(IMAGE_VERSION)-ubuntu20.04 -f Dockerfile.no-prebuilt .
images-ubuntu22.04:
	docker build --build-arg BASE_IMAGE=ubuntu:22.04 -t $(REGISTRY)/$(REGISTRY_PATH):$(IMAGE_VERSION)-ubuntu22.04 -f Dockerfile.no-prebuilt .
images-ubuntu24.04:
	docker build --build-arg BASE_IMAGE=ubuntu:24.04 -t $(REGISTRY)/$(REGISTRY_PATH):$(IMAGE_VERSION)-ubuntu24.04 -f Dockerfile.no-prebuilt .

# 依次构建上述三个基础镜像版本
images-all-bases: images-ubuntu20.04 images-ubuntu22.04 images-ubuntu24.04

# 禁用预编译，仅打包源码，缩短构建时间；运行时按当前内核即时编译
images-no-prebuilt:
	docker build -t $(REGISTRY)/$(REGISTRY_PATH):$(IMAGE_VERSION) -f Dockerfile.no-prebuilt .