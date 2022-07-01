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

#=========================================
# Add packages
#=========================================
echo '借来 luci-app-vsftpd'
svn co https://github.com/coolsnowwolf/luci/trunk/applications/luci-app-vsftpd feeds/luci/applications/luci-app-vsftpd
echo '连带依赖 vsftpd-alt'
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/vsftpd-alt package/lean/vsftpd-alt
./scripts/feeds update -i luci
./scripts/feeds install -p luci luci-app-vsftpd
# 顺便修改一些菜单入口到luci-app-vsftpd定义的nas一级中
sed -i 's/services/nas/' feeds/luci/applications/luci-app-ksmbd/root/usr/share/luci/menu.d/luci-app-ksmbd.json
sed -i 's/services/nas/' feeds/luci/applications/luci-app-hd-idle/root/usr/share/luci/menu.d/luci-app-hd-idle.json
sed -i 's/services/nas/' feeds/luci/applications/luci-app-aria2/root/usr/share/luci/menu.d/luci-app-aria2.json
sed -i 's/services/nas/' feeds/luci/applications/luci-app-transmission/root/usr/share/luci/menu.d/luci-app-transmission.json
# nps
echo '添加 luci-app-npc'
cd package
git clone https://github.com/lloyd18/luci-app-npc
git clone https://github.com/lloyd18/npc
cd ..

#=========================================
# Sys config modification
#=========================================
echo '修改网关地址'
sed -i 's/192.168.1.1/192.168.199.1/g' package/base-files/files/bin/config_generate

echo '修改时区'
sed -i "s/'UTC'/'CST-8'\n        set system.@system[-1].zonename='Asia\/Shanghai'/g" package/base-files/files/bin/config_generate

echo '修改机器名称'
sed -i 's/OpenWrt/JDC_Mark1/g' package/base-files/files/bin/config_generate

echo '修改默认主题'
# sed -i 's/luci-theme-bootstrap/luci-theme-argonne/g' feeds/luci/collections/luci*/Makefile
sed -i 's/bootstrap/argon/g' feeds/luci/modules/luci-base/root/etc/config/luci

target_inf() {
    #=========================================
    # Patch for model RE-SP-01B
    #=========================================
    echo -n '[diy-part2.sh]当前路径：' && pwd
    echo -n '[diy-part2.sh]当前物理路径：' && pwd -P

    # load dts
    echo '载入 mt7621_jdcloud_re-sp-01b.dts'
    curl --retry 3 -s 'https://gist.githubusercontent.com/1-1-2/335dbc8e138f39fb8fe6243d424fe476/raw/mt7621_jdcloud_re-sp-01b.dts' -o target/linux/ramips/dts/mt7621_jdcloud_re-sp-01b.dts

    # fix2 + fix4.2
    echo '修改 mt7621.mk'
    sed -i '/Device\/adslr_g7/i\define Device\/jdcloud_re-sp-01b\n  \$(Device\/dsa-migration)\n  \$(Device\/uimage-lzma-loader)\n  IMAGE_SIZE := 32448k\n  DEVICE_VENDOR := JDCloud\n  DEVICE_MODEL := RE-SP-01B\n  DEVICE_PACKAGES := kmod-fs-ext4 kmod-mt7603 kmod-mt7615e kmod-mt7615-firmware kmod-sdhci-mt7620 kmod-usb3 wpad-openssl\nendef\nTARGET_DEVICES += jdcloud_re-sp-01b\n\n' target/linux/ramips/image/mt7621.mk

    # fix3 + fix5.2
    echo '修改 02-network'
    sed -i -e '/lenovo,newifi-d1|\\/i\        jdcloud,re-sp-01b|\\' -e '/ramips_setup_macs/,/}/{/ampedwireless,ally-00x19k/i\        jdcloud,re-sp-01b)\n\t\tlan_mac=$(mtd_get_mac_ascii u-boot-env mac)\n\t\twan_mac=$(macaddr_add "$lan_mac" 1)\n\t\tlabel_mac=$lan_mac\n\t\t;;
    }' target/linux/ramips/mt7621/base-files/etc/board.d/02_network

    # fix5.1
    echo '修改 system.sh'
    sed -i 's#key"'\''=//p'\''#& \| head -n1#' package/base-files/files/lib/functions/system.sh

    #=========================================
    # Target System
    #=========================================
    cat >> .config << EOF
CONFIG_TARGET_ramips=y
CONFIG_TARGET_ramips_mt7621=y
CONFIG_TARGET_ramips_mt7621_DEVICE_jdcloud_re-sp-01b=y
EOF
}

config_clean() {
    rm -f ./.config*    # 清理重开
    target_inf

    #=========================================
    # Stripping options
    #=========================================
    cat >> .config << EOF
CONFIG_STRIP_KERNEL_EXPORTS=y
# CONFIG_USE_MKLIBS=y
EOF
    #=========================================
    # Luci
    #=========================================
    cat >> .config << EOF
CONFIG_PACKAGE_luci=y
CONFIG_LUCI_LANG_zh_Hans=y
EOF
}

config_basic() {
    config_clean
    #=========================================
    # 基础包和应用
    #=========================================
    cat >> .config << EOF
CONFIG_PACKAGE_luci-app-acl=y
CONFIG_PACKAGE_luci-app-advanced=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-app-statistics=y
CONFIG_PACKAGE_luci-app-store=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-wol=y
# ----------automount
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_kmod-fs-ext4=y
CONFIG_PACKAGE_kmod-fs-exfat=y
CONFIG_PACKAGE_kmod-fs-ntfs=y
# ----------extra packages-ipv6helper
CONFIG_PACKAGE_ipv6helper=y
# ----------Utilities-Disc-cfdisk&fdisk
CONFIG_PACKAGE_cfdisk=y
CONFIG_PACKAGE_fdisk=y
# ----------Utilities-Filesystem-e2fsprogs
CONFIG_PACKAGE_e2fsprogs=y
# ----------Utilities-usbutils
CONFIG_PACKAGE_usbutils=y
# ----------Utilities-jq
CONFIG_PACKAGE_jq=y
# ----------Utilities-coreutils-base64
CONFIG_PACKAGE_coreutils-base64=y
# ----------Kernel modules-USB Support-kmod-usb3
CONFIG_DEFAULT_kmod-usb3=y
# ----------luci-app-hd-idle
CONFIG_PACKAGE_luci-app-hd-idle=y
# ----------luci-app-ksmbd
CONFIG_PACKAGE_luci-app-ksmbd=y
# ----------luci-app-commands
CONFIG_PACKAGE_luci-app-commands=y
# ----------luci-app-qos
CONFIG_PACKAGE_luci-app-qos=y
# ----------luci-app-eqos
CONFIG_PACKAGE_luci-app-eqos=y
# ----------luci-app-sqm
CONFIG_PACKAGE_luci-app-sqm=y
# ----------luci-app-ttyd
CONFIG_PACKAGE_luci-app-ttyd=y
# ----------luci-theme-argon
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_luci-theme-argon=y
CONFIG_PACKAGE_luci-app-argon-config=y
EOF
}

config_func() {
    config_basic
    #=========================================
    # 功能包
    #=========================================
    cat >> .config << EOF
# ----------luci-app-vsftpd
CONFIG_PACKAGE_luci-app-vsftpd=y
# ----------luci-app-aria2
CONFIG_PACKAGE_luci-app-aria2=y
# ----------luci-app-VPNs
CONFIG_PACKAGE_luci-app-npc=y
CONFIG_PACKAGE_luci-app-frpc=y
# ----------luci-app-openclash
CONFIG_PACKAGE_luci-app-openclash=y
# CONFIG_PACKAGE_dnsmasq is not set
# ----------network-firewall-ip6tables-ip6tables-mod-nat
# CONFIG_PACKAGE_ip6tables-mod-nat=y
# ----------luci-app-transmission
CONFIG_PACKAGE_luci-app-transmission=y
# ----------luci-app-watchcat
CONFIG_PACKAGE_luci-app-watchcat=y
EOF
}

config_test() {
    config_func
    #=========================================
    # 测试域
    #=========================================
    cat >> .config << EOF
# CONFIG_PACKAGE_luci-app-verysync=y
EOF
}

#↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑上面写配置区块内容↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
#--------------------------------------------------------------------------------
#↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓下面写配置编写逻辑↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

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
