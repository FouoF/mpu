# 按各 Ubuntu 版本对应的内核列表（hack/kernels_ubuntu*.txt）在各自镜像内安装 headers 并构建，
# 使用预设的 KVERSION 而非 uname -r，构建结果合并到最终镜像 /mpu/build/<kver>/mpu.ko
FROM ubuntu:20.04 AS build-20
SHELL ["/bin/bash", "-c"]
WORKDIR /mpu
COPY . /mpu
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && bash /mpu/hack/docker_build_kernels.sh /mpu/hack/kernels_ubuntu20.04.txt ubuntu20.04 \
    && rm -rf /var/lib/apt/lists/*

FROM ubuntu:22.04 AS build-22
SHELL ["/bin/bash", "-c"]
WORKDIR /mpu
COPY . /mpu
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && bash /mpu/hack/docker_build_kernels.sh /mpu/hack/kernels_ubuntu22.04.txt ubuntu22.04 \
    && rm -rf /var/lib/apt/lists/*

FROM ubuntu:24.04 AS build-24
SHELL ["/bin/bash", "-c"]
WORKDIR /mpu
COPY . /mpu
RUN apt-get update && apt-get install -y --no-install-recommends build-essential \
    && bash /mpu/hack/docker_build_kernels.sh /mpu/hack/kernels_ubuntu24.04.txt ubuntu24.04 \
    && rm -rf /var/lib/apt/lists/*

# 最终镜像：源码 + 各阶段构建的 build/<kver>/mpu.ko；基础镜像可通过 build-arg BASE_IMAGE 指定
ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE}
WORKDIR /mpu
COPY . /mpu
COPY --from=build-20 /out/. /mpu/build/
COPY --from=build-22 /out/. /mpu/build/
COPY --from=build-24 /out/. /mpu/build/
CMD ["/bin/bash", "-c", "bash run.sh install && sleep infinity"]
