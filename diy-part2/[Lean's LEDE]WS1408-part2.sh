#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 载入闪存对应的DIY脚本
sh_dir=$(dirname "$0")
. $sh_dir/OpenWrt-Configurator-ARM.sh

mod_default_config(){
    #=========================================
    # 三种类型：
    # C1： 修改 package/base-files/files/bin/config_generate 配置生成脚本
    # C2： 修改 luci 包默认配置
    # C3： 添加默认 uci-default 脚本
    #=========================================

    # C1
    echo '修改时区为东八区'
    sed -i "s/'UTC'/'CST-8'\n        set system.@system[-1].zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate

    echo '修改主机名为 WS1408'
    sed -i 's/OpenWrt/WS1408/g' package/base-files/files/bin/config_generate

    # C2
    echo '修改默认主题为老竭力的 argon'
    # sed -i 's/luci-theme-bootstrap/luci-theme-argonne/g' feeds/luci/collections/luci*/Makefile
    sed -i 's/bootstrap/argon/g' feeds/luci/modules/luci-base/root/etc/config/luci

    # C3
    echo '添加 OpenWrt 默认设置文件'
    mkdir -p files/etc/uci-defaults
    cp -v "$sh_dir/[OpenWrt]CustomDefault.sh" files/etc/uci-defaults/99-Custom-Default
}

target_inf() {
    echo -n '[diy-part2.sh]当前表显路径：' && pwd
    echo -n '[diy-part2.sh]当前物理路径：' && pwd -P
    #=========================================
    # Target System
    #=========================================
    cat >> .config << EOF
CONFIG_TARGET_meson=y
CONFIG_TARGET_meson_meson8b=y
CONFIG_TARGET_meson_meson8b_DEVICE_odroid-c1=y
CONFIG_TARGET_INITRAMFS_COMPRESSION_NONE=y
CONFIG_TARGET_ROOTFS_INITRAMFS=y
CONFIG_TARGET_ROOTFS_TARGZ=y
EOF
}

#↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑上面写配置区块内容↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
#--------------------------------------------------------------------------------
#↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓下面写配置编写逻辑↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

add_packages
# 清理重开，从零开始
rm -fv ./.config*
target_inf
mod_default_config

# 根据输入参数增加内容
if [[ $1 == clean* ]]; then
    echo "[洁净配置] 仅该型号的默认功能"
    config_clean
elif [[ $1 == basic* ]]; then
    echo "[基本配置] 包含一些基础增强"
    config_basic
elif [[ $1 == test* ]]; then
    echo "[测试配置] 包含所有功能，外加测试包"
    config_test
else
    echo "[全功能配置] 包含常用的所有功能、插件"
    config_func
fi

# 移除行首的空格和制表符
sed -i 's/^[ \t]*//g' .config
# make defconfig
# diff .config default.config --color

# diff的返回值1会导致github actions出错，用这个来盖过去
echo "[脚本完成] diy-part2.sh 结束，已生成 .config 文件"