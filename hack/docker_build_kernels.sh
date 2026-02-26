#!/usr/bin/env bash
# 在容器构建阶段使用：按内核列表安装 headers 并构建 mpu.ko 到 /out/<kver>/
# 用法: hack/docker_build_kernels.sh <kernels_ubuntuXX.04.txt> <阶段名，如 ubuntu20.04>
set -e
LIST_FILE="$1"
STAGE_NAME="${2:-build}"
[[ -f "$LIST_FILE" ]] || { echo "Missing list file: $LIST_FILE"; exit 1; }

cd /mpu
while read -r kver || [[ -n "$kver" ]]; do
    kver=$(echo "$kver" | tr -d '\r' | xargs)
    [[ -z "$kver" || "$kver" =~ ^# ]] && continue
    echo "Building for kernel $kver ($STAGE_NAME)..."
    apt-get install -y -qq "linux-headers-$kver" || { echo "Skip $kver: headers not found"; continue; }
    make KVERSION="$kver" && mkdir -p "/out/$kver" && cp /mpu/mpu.ko "/out/$kver/" && make KVERSION="$kver" clean
done < "$LIST_FILE"
