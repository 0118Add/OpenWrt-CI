#!/bin/bash
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

echo "开始配置……"
echo "========================="

chmod +x ${GITHUB_WORKSPACE}/immortalwrt/function.sh
source ${GITHUB_WORKSPACE}/immortalwrt/function.sh

mirror="https://raw.githubusercontent.com/sbwml/r4s_build_script/refs/heads/master"
github="github.com"
gitea="git.cooluc.com"

# 更改主机名
#sed -i "s/hostname='.*'/hostname='OpenWrt'/g" package/base-files/files/bin/config_generate

# 更改固件版本信息
#sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION=''|g" package/base-files/files/etc/openwrt_release
#sed -i "s|DISTRIB_DESCRIPTION='.*'|DISTRIB_DESCRIPTION='OpenWrt %V'|g" package/base-files/files/etc/openwrt_release

# 修改x86内核到6.6版
#sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.12/g' ./target/linux/x86/Makefile

# 修改默认IP
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 修改连接数
sed -i 's/net.netfilter.nf_conntrack_max=.*/net.netfilter.nf_conntrack_max=65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# 修正连接数
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=165535' package/base-files/files/etc/sysctl.conf

# autocore default-settings
#rm -rf package/emortal/autocore
#rm -rf package/emortal/default-settings
#merge_package main https://github.com/0118Add/Openwrt-CI package/Openwrt-CI autocore
#git clone --depth=1 -b openwrt-25.12 https://github.com/sbwml/autocore-arm package/autocore
#git clone https://github.com/sbwml/default-settings package/default-settings

# passwall核心库
rm -rf feeds/luci/applications/{luci-app-daed,luci-app-openclash}
rm -rf feeds/packages/net/{daed,v2ray-geodata,xray-core}
#git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages
merge_package main https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall-packages v2ray-geodata xray-core

# openclash
git clone --depth=1 -b dev https://github.com/vernesong/OpenClash package/OpenClash

# homeproxy
#git clone --depth=1 -b dev https://github.com/immortalwrt/homeproxy package/luci-app-homeproxy
sed -i "s/ImmortalWrt/OpenWrt/g" feeds/luci/applications/luci-app-homeproxy/po/zh_Hans/homeproxy.po
sed -i "s/ImmortalWrt proxy/OpenWrt proxy/g" feeds/luci/applications/luci-app-homeproxy/htdocs/luci-static/resources/view/homeproxy/{client.js,server.js}

# clashoo
git clone https://github.com/kenzok8/openwrt-clashoo package/clashoo

# mihomo momo
#git clone https://github.com/nikkinikki-org/OpenWrt-nikki  package/OpenWrt-nikki
#git clone -b main --depth 1 https://github.com/nikkinikki-org/OpenWrt-momo package/OpenWrt-momo

# dae daed
git clone --depth=1 -b kix https://github.com/QiuSimons/luci-app-daed package/daed
git clone https://github.com/QiuSimons/vmlinux-btf package/vmlinux-btf
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:=2026.06.14/g' package/daed/daed/Makefile
sed -i 's/DAED_VERSION:=.*/DAED_VERSION:=daed-4d6a433/g' package/daed/daed/Makefile
sed -i 's/WING_VERSION:=.*/WING_VERSION:=wing-dc50308/g' package/daed/daed/Makefile
sed -i 's/CORE_VERSION:=.*/CORE_VERSION:=core-5a51cc7/g' package/daed/daed/Makefile
sed -i 's/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=4d6a43331f2f6e25961935b9e7ac09a7568bb2b4/g' package/daed/daed/Makefile

# partexp
git clone https://github.com/sirpdboy/luci-app-partexp package/luci-app-partexp

# tailscale zerotier
#git clone https://github.com/Jaykwok2999/luci-app-tailscale  package/luci-app-tailscale
sed -i 's/vpn/services/g' feeds/luci/applications/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json

# golang 27.x
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 27.x feeds/packages/lang/golang

# 预编译 node
#rm -rf feeds/packages/lang/node/node
#git clone --depth=1 -b packages-25.12 https://github.com/sbwml/feeds_packages_lang_node-prebuilt feeds/packages/lang/node/node

# luci-app-filemanager
rm -rf feeds/luci/applications/luci-app-filemanager
git clone https://github.com/sbwml/luci-app-filemanager package/luci-app-filemanager

# curl
rm -rf feeds/packages/net/curl
git clone https://github.com/sbwml/feeds_packages_net_curl feeds/packages/net/curl

# 音乐解锁
sed -i 's/解除网易云音乐播放限制/音乐解锁/g' feeds/luci/applications/luci-app-unblockneteasemusic/root/usr/share/luci/menu.d/luci-app-unblockneteasemusic.json

# 调整Dockerman到服务菜单
rm -rf feeds/luci/applications/luci-app-dockerman
git clone https://github.com/sbwml/luci-app-dockerman feeds/luci/applications/luci-app-dockerman
#rm -rf feeds/packages/utils/{docker,dockerd,containerd,runc}
#git clone https://github.com/sbwml/packages_utils_docker feeds/packages/utils/docker
#git clone https://github.com/sbwml/packages_utils_dockerd feeds/packages/utils/dockerd
#git clone https://github.com/sbwml/packages_utils_containerd feeds/packages/utils/containerd
#git clone https://github.com/sbwml/packages_utils_runc feeds/packages/utils/runc
sed -i 's/"admin/"admin\/services/g' feeds/luci/applications/luci-app-dockerman/root/usr/share/luci/menu.d/luci-app-dockerman.json

# 自定义配置,替换文件
#sed -i '/exit 0$/d' package/emortal/default-settings/files/99-default-settings
#cat ${GITHUB_WORKSPACE}/immortalwrt/default-settings >> package/emortal/default-settings/files/99-default-settings
#curl -fsSL https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/patch/25.12/10_system.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
#curl -fsSL https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/lede/10_system.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
curl -fsSL https://raw.githubusercontent.com/0118Add/X86-Actions/main/general/25_storage.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/25_storage.js
#curl -fsSL https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/immortalwrt/29_ports.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/29_ports.js
#curl -fsSL https://raw.githubusercontent.com/0118Add/build-openwrt/master/scripts/30_network.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/30_network.js
#wget -O package/autocore/files/generic/10_system.js https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/patch/25.12/10_system.js
#wget -O package/autocore/files/generic/29_ports.js https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/x86/diy/x86_lede/29_ports.js

# comment out the following line to restore the full description
#sed -i '/# timezone/i grep -q '\''/tmp/sysinfo/model'\'' /etc/rc.local || sudo sed -i '\''/exit 0/i [ "$(cat /sys\\/class\\/dmi\\/id\\/sys_vendor 2>\\/dev\\/null)" = "Default string" ] \&\& echo "x86_64" > \\/tmp\\/sysinfo\\/model'\'' /etc/rc.local\n' package/emortal/default-settings/files/99-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''ImmortalWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''ImmortalWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI Master\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''\'\'', branch = '\''LuCI Master'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/emortal/default-settings/files/99-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''ImmortalWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''ImmortalWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI Master\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI Master'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/emortal/default-settings/files/99-default-settings
#curl -fsSL https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/patch/25.12/os-release > package/base-files/files/etc/os-release

# 移除luci-app-attendedsysupgrade
sed -i "/attendedsysupgrade/d" $(find ./feeds/luci/collections/ -type f -name "Makefile")

# 移除luci-app-attendedsysupgrade
#sed -i '18d' feeds/luci/collections/luci-nginx/Makefile
#sed -i '17d' feeds/luci/collections/luci/Makefile
#sed -i '16s/ \\$//' feeds/luci/collections/luci/Makefile

rm -rf feeds/luci/applications/luci-app-mjpg-streamer
rm -rf feeds/packages/net/onionshare-cli

./scripts/feeds update -a
./scripts/feeds install -a

echo "========================="
echo "配置完成……"
