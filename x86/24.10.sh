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

# 更改主机名
#sed -i "s/hostname='.*'/hostname='ImmortalWrt'/g" package/base-files/files/bin/config_generate

# 更改固件版本信息
#sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION=''|g" package/base-files/files/etc/openwrt_release
#sed -i "s|DISTRIB_DESCRIPTION='.*'|DISTRIB_DESCRIPTION='OpenWrt %V'|g" package/base-files/files/etc/openwrt_release

# 修改x86内核到6.6版
#sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.6/g' ./target/linux/x86/Makefile

# 内核替换
#sed -i 's/LINUX_KERNEL_HASH-6.6.71 = 219715ba2dcfa6539fba09ad3f9212772f3507189eb60d77f8e89b06c32e724e/LINUX_KERNEL_HASH-6.6.66 = 9d757937c4661c2f512c62641b74ef74eff9bb13dc5dbcbaaa108c21152f1e52/g' ./include/kernel-6.6
#sed -i 's/LINUX_VERSION-6.6 = .71/LINUX_VERSION-6.6 = .66/g' ./include/kernel-6.6

# 修改默认IP
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 修改连接数
sed -i 's/net.netfilter.nf_conntrack_max=.*/net.netfilter.nf_conntrack_max=65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# 修正连接数
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=165535' package/base-files/files/etc/sysctl.conf

# golang 26.x
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# 预编译 node
rm -rf feeds/packages/lang/node
git clone --depth=1 -b packages-24.10 https://github.com/sbwml/feeds_packages_lang_node-prebuilt feeds/packages/lang/node

# SmartDNS ZeroTier
#rm -rf feeds/luci/applications/luci-app-smartdns
#rm -rf feeds/luci/applications/luci-app-zerotier
#git clone --single-branch https://github.com/lwb1978/luci-app-smartdns package/luci-app-smartdns
#git clone https://github.com/lwb1978/luci-app-zerotier package/luci-app-zerotier
#sed -i 's/vpn/services/g' package/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json
sed -i 's/vpn/services/g' feeds/luci/applications/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json
# 替换immortalwrt 软件仓库smartdns版本为官方最新版
#rm -rf feeds/packages/net/smartdns
#cp -rf ${GITHUB_WORKSPACE}/patch/smartdns feeds/packages/net

# openclash
rm -rf feeds/luci/applications/luci-app-openclash
git clone --depth=1 -b master https://github.com/vernesong/OpenClash package/OpenClash

# homeproxy
#rm -rf feeds/luci/applications/luci-app-homeproxy
#git clone --depth 1 -b dev https://github.com/immortalwrt/homeproxy

# mihomo
#git clone https://github.com/nikkinikki-org/OpenWrt-nikki  package/OpenWrt-nikki
#git clone https://github.com/nikkinikki-org/OpenWrt-momo package/OpenWrt-momo

# clashoo
git clone https://github.com/kenzok8/openwrt-clashoo package/clashoo

# partexp
git clone https://github.com/sirpdboy/luci-app-partexp package/luci-app-partexp

# 音乐解锁
sed -i 's/解除网易云音乐播放限制/音乐解锁/g' feeds/luci/applications/luci-app-unblockneteasemusic/root/usr/share/luci/menu.d/luci-app-unblockneteasemusic.json

# 调整Dockerman到服务菜单
rm -rf feeds/luci/applications/luci-app-dockerman
git clone -b master --depth 1 https://github.com/lisaac/luci-app-dockerman package/luci-app-dockerman
#git clone --depth=1 -b openwrt-25.12 https://github.com/coolsnowwolf/luci.git coolsnowwolf-luci
#cp -rf coolsnowwolf-luci/collections/luci-lib-docker feeds/luci/collections/luci-lib-docker
#ln -sf ../../../feeds/luci/collections/luci-lib-docker ./package/feeds/luci/luci-lib-docker
#rm -rf feeds/packages/utils/{docker,dockerd,containerd,runc}
#git clone https://github.com/sbwml/packages_utils_docker feeds/packages/utils/docker
#git clone https://github.com/sbwml/packages_utils_dockerd feeds/packages/utils/dockerd
#git clone https://github.com/sbwml/packages_utils_containerd feeds/packages/utils/containerd
#git clone https://github.com/sbwml/packages_utils_runc feeds/packages/utils/runc
sed -i 's/"admin",/"admin","services",/g' package/luci-app-dockerman/applications/luci-app-dockerman/luasrc/controller/*.lua
sed -i 's/"admin/"admin\/services/g' package/luci-app-dockerman/applications/luci-app-dockerman/luasrc/model/*.lua
sed -i 's/"admin/"admin\/services/g' package/luci-app-dockerman/applications/luci-app-dockerman/luasrc/model/cbi/dockerman/*.lua
sed -i 's/"admin/"admin\/services/g' package/luci-app-dockerman/applications/luci-app-dockerman/luasrc/view/dockerman/*.htm
sed -i 's/"admin/"admin\/services/g' package/luci-app-dockerman/applications/luci-app-dockerman/luasrc/view/dockerman/cbi/*.htm

# 自定义默认配置
#sed -i '/exit 0$/d' package/emortal/default-settings/files/99-default-settings
#cat ${GITHUB_WORKSPACE}/immortalwrt/default-settings >> package/emortal/default-settings/files/99-default-settings
#curl -fsSL https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/patch/10_system.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
curl -fsSL https://raw.githubusercontent.com/0118Add/X86-N1-Actions/main/general/25_storage.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/25_storage.js
#curl -fsSL https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/immortalwrt/29_ports.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/29_ports.js

# comment out the following line to restore the full description
#sed -i '/# timezone/i grep -q '\''/tmp/sysinfo/model'\'' /etc/rc.local || sudo sed -i '\''/exit 0/i [ "$(cat /sys\\/class\\/dmi\\/id\\/sys_vendor 2>\\/dev\\/null)" = "Default string" ] \&\& echo "x86_64" > \\/tmp\\/sysinfo\\/model'\'' /etc/rc.local\n' package/emortal/default-settings/files/99-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''ImmortalWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''ImmortalWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-24.10\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''\'\'', branch = '\''LuCI openwrt-24.10'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/emortal/default-settings/files/99-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''ImmortalWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''ImmortalWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-24.10\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI openwrt-24.10'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/emortal/default-settings/files/99-default-settings
#curl -fsSL https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/patch/release > package/base-files/files/etc/os-release

# 移除 luci-app-attendedsysupgrade
sed -i '18d' feeds/luci/collections/luci-nginx/Makefile
sed -i '17d' feeds/luci/collections/luci/Makefile
sed -i '16s/ \\$//' feeds/luci/collections/luci/Makefile

# rust版本以免编译失败
sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

rm -rf feeds/packages/admin/zabbix

# 拷贝自定义文件
if [ -n "$(ls -A "${GITHUB_WORKSPACE}/immortalwrt/diy" 2>/dev/null)" ]; then
	cp -Rf ${GITHUB_WORKSPACE}/immortalwrt/diy/* .
fi

./scripts/feeds update -a
./scripts/feeds install -a

echo "========================="
echo "配置完成……"
