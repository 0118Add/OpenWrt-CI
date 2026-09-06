#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part02.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)

echo "开始配置……"
echo "========================="

function merge_package(){
    repo=`echo $1 | rev | cut -d'/' -f 1 | rev`
    pkg=`echo $2 | rev | cut -d'/' -f 1 | rev`
    # find package/ -follow -name $pkg -not -path "package/custom/*" | xargs -rt rm -rf
    git clone --depth=1 --single-branch $1
    mv $2 package/custom/
    rm -rf $repo
}
function drop_package(){
    find package/ -follow -name $1 -not -path "package/custom/*" | xargs -rt rm -rf
}
function merge_feed(){
    if [ ! -d "feed/$1" ]; then
        echo >> feeds.conf.default
        echo "src-git $1 $2" >> feeds.conf.default
    fi
    ./scripts/feeds update $1
    ./scripts/feeds install -a -p $1
}
rm -rf package/custom; mkdir package/custom

#mirror="https://raw.githubusercontent.com/sbwml/r4s_build_script/refs/heads/master"
mirror="https://raw.githubusercontent.com/gitbruc/myopenwrt/refs/heads/new"
github="github.com"
gitea="git.cooluc.com"

# Modify default IP
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 修改x86内核版本
#sed -i 's/KERNEL_PATCHVER:=.*/KERNEL_PATCHVER:=6.18/g' ./target/linux/x86/Makefile

# 更改固件版本信息
#sed -i "s|DISTRIB_REVISION='.*'|DISTRIB_REVISION=''|g" package/base-files/files/etc/openwrt_release
#sed -i "s|DISTRIB_DESCRIPTION='.*'|DISTRIB_DESCRIPTION='OpenWrt 23.05'|g" package/base-files/files/etc/openwrt_release
#sed -i "s|DISTRIB_DESCRIPTION='.*'|DISTRIB_DESCRIPTION='OpenWrt SNAPSHOT'|g" package/base-files/files/etc/openwrt_release

# 内核替换 kernel xxx
#sed -i 's/LINUX_KERNEL_HASH-5.15.139 = 9c68c10dfe18e59b892e940436dea6a18d167160d55e62563cf7282244d8044e/LINUX_KERNEL_HASH-5.15.138 = af84e54164e1c01f59764ba528448ed36b377d22aafbd81b4b0cf47792ef4aaa/g' ./include/kernel-5.15
#sed -i 's/LINUX_VERSION-5.15 = .139/LINUX_VERSION-5.15 = .138/g' ./include/kernel-5.15

# 修改连接数
sed -i 's/net.netfilter.nf_conntrack_max=.*/net.netfilter.nf_conntrack_max=65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# 修正连接数
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=165535' package/base-files/files/etc/sysctl.conf

# golang 27.x
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 27.x feeds/packages/lang/golang

# 预编译 node
rm -rf feeds/packages/lang/node
git clone --depth=1 -b packages-25.12 https://github.com/sbwml/feeds_packages_lang_node-prebuilt feeds/packages/lang/node

# 文件替换
#wget -O ./package/base-files/files/etc/banner https://raw.githubusercontent.com/0118Add/X86_64-Test/main/general/banner
#wget -O ./package/libs/libnftnl/Makefile https://raw.githubusercontent.com/0118Add/X86_64-Test/main/patch/Makefile

# autoCore
git clone https://github.com/sbwml/autocore-arm -b openwrt-25.12 package/autocore

# Default settings
git clone https://github.com/sbwml/default-settings package/default-settings

# OpenClash
git clone -b dev --depth 1 https://github.com/vernesong/OpenClash package/OpenClash

# Shared for PassWall and ShadowsocksR Plus+
rm -rf feeds/packages/net/{xray-core,sing-box,v2ray-geodata}
#git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages -b main
#git clone -b main --single-branch https://github.com/Openwrt-Passwall/openwrt-passwall package/openwrt-passwall
#merge_package https://github.com/kiddin9/op-packages op-packages/luci-app-passwall
merge_package https://github.com/Openwrt-Passwall/openwrt-passwall-packages openwrt-passwall-packages/sing-box
merge_package https://github.com/Openwrt-Passwall/openwrt-passwall-packages openwrt-passwall-packages/xray-core
merge_package https://github.com/Openwrt-Passwall/openwrt-passwall-packages openwrt-passwall-packages/v2ray-geodata

# homeproxy
git clone -b main --depth 1 https://github.com/szwjp/luci-app-homeproxy package/luci-app-homeproxy
#git clone --depth 1 -b master https://github.com/fun200/homeproxy_plus package/luci-app-homeproxy
#merge_package https://github.com/VIKINGYFY/packages packages/luci-app-homeproxy
#merge_package https://github.com/VIKINGYFY/packages packages/sing-box
sed -i "s/ImmortalWrt/OpenWrt/g" package/luci-app-homeproxy/po/zh_Hans/homeproxy.po
sed -i "s/ImmortalWrt proxy/OpenWrt proxy/g" package/luci-app-homeproxy/htdocs/luci-static/resources/view/homeproxy/{client.js,server.js}
#wget -O package/luci-app-homeproxy/root/etc/init.d/homeproxy https://raw.githubusercontent.com/0118Add/X86-Actions/main/general/homeproxy

# mihomo
#git clone https://github.com/nikkinikki-org/OpenWrt-nikki package/OpenWrt-nikki
#git clone https://github.com/nikkinikki-org/OpenWrt-momo package/OpenWrt-momo

# dae daed
#git clone https://github.com/kenzok8/openwrt-daede package/daede
#git clone -b kix --depth 1 https://github.com/QiuSimons/luci-app-dae package/dae
git clone -b kix --depth 1 https://github.com/QiuSimons/luci-app-daed package/daed
git clone https://github.com/QiuSimons/vmlinux-btf package/vmlinux-btf
sed -i 's/PKG_VERSION:=.*/PKG_VERSION:=2026.06.14/g' package/daed/daed/Makefile
sed -i 's/DAED_VERSION:=.*/DAED_VERSION:=daed-4d6a433/g' package/daed/daed/Makefile
sed -i 's/WING_VERSION:=.*/WING_VERSION:=wing-dc50308/g' package/daed/daed/Makefile
sed -i 's/CORE_VERSION:=.*/CORE_VERSION:=core-5a51cc7/g' package/daed/daed/Makefile
sed -i 's/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=4d6a43331f2f6e25961935b9e7ac09a7568bb2b4/g' package/daed/daed/Makefile

# ttyd
sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i '3 a\\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

# partexp
git clone https://github.com/sirpdboy/luci-app-partexp package/luci-app-partexp

# luci-app-filemanager
rm -rf feeds/luci/applications/luci-app-filemanager
git clone https://github.com/sbwml/luci-app-filemanager package/luci-app-filemanager

# tailscale
#git clone https://github.com/Jaykwok2999/luci-app-tailscale  package/luci-app-tailscale
#sed -i 's/vpn/services/g' package/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json

# zerotier
rm -rf feeds/packages/utils/coremark
rm -rf feeds/luci/applications/luci-app-mjpg-streamer
rm -rf feeds/luci/applications/luci-app-zerotier
git clone https://github.com/8688Add/luci-app-zerotier package/luci-app-zerotier
merge_package https://github.com/8688Add/openwrt_pkgs openwrt_pkgs/coremark
sed -i 's/vpn/services/g' package/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json

# unblockneteasemusic
#git clone https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic.git package/luci-app-unblockneteasemusic
#sed -i 's/解除网易云音乐播放限制/音乐解锁/g' package/luci-app-unblockneteasemusic/root/usr/share/luci/menu.d/luci-app-unblockneteasemusic.json

# 克隆immortalwrt-luci packages仓库
git clone --depth=1 -b openwrt-25.12 https://github.com/immortalwrt/luci.git immortalwrt-luci
cp -rf immortalwrt-luci/applications/luci-app-diskman feeds/luci/applications/luci-app-diskman
ln -sf ../../../feeds/luci/applications/luci-app-diskman ./package/feeds/luci/luci-app-diskman
#cp -rf immortalwrt-luci/applications/luci-app-homeproxy feeds/luci/applications/luci-app-homeproxy
#ln -sf ../../../feeds/luci/applications/luci-app-homeproxy ./package/feeds/luci/luci-app-homeproxy
cp -rf immortalwrt-luci/applications/luci-app-msd_lite feeds/luci/applications/luci-app-msd_lite
ln -sf ../../../feeds/luci/applications/luci-app-msd_lite ./package/feeds/luci/luci-app-msd_lite
cp -rf immortalwrt-luci/applications/luci-app-ramfree feeds/luci/applications/luci-app-ramfree
ln -sf ../../../feeds/luci/applications/luci-app-ramfree ./package/feeds/luci/luci-app-ramfree
cp -rf immortalwrt-luci/applications/luci-app-unblockneteasemusic feeds/luci/applications/luci-app-unblockneteasemusic
ln -sf ../../../feeds/luci/applications/luci-app-unblockneteasemusic ./package/feeds/luci/luci-app-unblockneteasemusic
git clone --depth=1 -b openwrt-25.12 https://github.com/immortalwrt/packages.git immortalwrt-packages
cp -rf immortalwrt-packages/net/msd_lite feeds/packages/net/msd_lite
ln -sf ../../../feeds/packages/net/msd_lite ./package/feeds/packages/msd_lite
#cp -rf immortalwrt-packages/net/sing-box feeds/packages/net/sing-box
#ln -sf ../../../feeds/packages/net/sing-box ./package/feeds/packages/sing-box
sed -i 's/解除网易云音乐播放限制/音乐解锁/g' feeds/luci/applications/luci-app-unblockneteasemusic/root/usr/share/luci/menu.d/luci-app-unblockneteasemusic.json
#sed -i "s/ImmortalWrt/OpenWrt/g" feeds/luci/applications/luci-app-homeproxy/po/zh_Hans/homeproxy.po
#sed -i "s/ImmortalWrt proxy/OpenWrt proxy/g" feeds/luci/applications/luci-app-homeproxy/htdocs/luci-static/resources/view/homeproxy/{client.js,server.js}

# Dockerman
rm -rf feeds/luci/applications/luci-app-dockerman
git clone https://github.com/sbwml/luci-app-dockerman feeds/luci/applications/luci-app-dockerman
#rm -rf feeds/packages/utils/{docker,dockerd,containerd,runc}
#git clone https://github.com/sbwml/packages_utils_docker feeds/packages/utils/docker
#git clone https://github.com/sbwml/packages_utils_dockerd feeds/packages/utils/dockerd
#git clone https://github.com/sbwml/packages_utils_containerd feeds/packages/utils/containerd
#git clone https://github.com/sbwml/packages_utils_runc feeds/packages/utils/runc
sed -i 's/"admin/"admin\/services/g' feeds/luci/applications/luci-app-dockerman/root/usr/share/luci/menu.d/luci-app-dockerman.json
#sed -i 's/"admin",/"admin","services",/g' package/dockerman/applications/luci-app-dockerman/luasrc/controller/*.lua
#sed -i 's/"admin/"admin\/services/g' package/dockerman/applications/luci-app-dockerman/luasrc/model/*.lua
#sed -i 's/"admin/"admin\/services/g' package/dockerman/applications/luci-app-dockerman/luasrc/model/cbi/dockerman/*.lua
#sed -i 's/"admin/"admin\/services/g' package/dockerman/applications/luci-app-dockerman/luasrc/view/dockerman/*.htm
#sed -i 's/"admin/"admin\/services/g' package/dockerman/applications/luci-app-dockerman/luasrc/view/dockerman/cbi/*.htm

# turboacc
#git clone https://github.com/chenmozhijin/turboacc package/turboacc
#sed -i '/PKG_INSTALL:=/iPKG_FIXUP:=autoreconf' package/libs/libnftnl/Makefile
#curl -sSL https://raw.githubusercontent.com/mufeng05/openwrt-sonic-fullcone/master/add_sonic_fullcone.sh -o add_sonic_fullcone.sh && bash add_sonic_fullcone.sh
#curl -sSL https://raw.githubusercontent.com/mufeng05/turboacc/main/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh
#sed -i 's/Turbo ACC 网络加速/网络加速/g' package/turboacc/luci-app-turboacc/po/zh_Hans/turboacc.po

# Shortcut Forwarding Engine
git clone https://$gitea/sbwml/shortcut-fe package/shortcut-fe

# Patch FireWall 4
rm -rf package/network/config/firewall4/patches
# firewall4
mkdir -p package/network/config/firewall4/patches
# fullcone
curl -s $mirror/openwrt/patch/firewall4/firewall4_patches/999-01-firewall4-add-fullcone-support.patch > package/network/config/firewall4/patches/999-01-firewall4-add-fullcone-support.patch
# bcm fullcone
curl -s $mirror/openwrt/patch/firewall4/firewall4_patches/999-02-firewall4-add-bcm-fullconenat-support.patch > package/network/config/firewall4/patches/999-02-firewall4-add-bcm-fullconenat-support.patch
# fix flow offload
curl -s $mirror/openwrt/patch/firewall4/firewall4_patches/001-fix-fw4-flow-offload.patch > package/network/config/firewall4/patches/001-fix-fw4-flow-offload.patch
# add custom nft command support
curl -s $mirror/openwrt/patch/firewall4/100-openwrt-firewall4-add-custom-nft-command-support.patch | patch -p1
# fw4 - github mirror
sed -i 's|$(PROJECT_GIT)/project|https://github.com/openwrt|g' package/network/config/firewall4/Makefile
# libnftnl
mkdir -p package/libs/libnftnl/patches
curl -s $mirror/openwrt/patch/firewall4/libnftnl/0001-libnftnl-add-fullcone-expression-support.patch > package/libs/libnftnl/patches/0001-libnftnl-add-fullcone-expression-support.patch
curl -s $mirror/openwrt/patch/firewall4/libnftnl/0002-libnftnl-add-brcm-fullcone-support.patch > package/libs/libnftnl/patches/0002-libnftnl-add-brcm-fullcone-support.patch
# fix build on rhel9
sed -i '/^PKG_BUILD_FLAGS[[:space:]]*:/aPKG_FIXUP:=autoreconf' package/libs/libnftnl/Makefile
# nftables
mkdir -p package/network/utils/nftables/patches
curl -s $mirror/openwrt/patch/firewall4/nftables/0001-nftables-add-fullcone-expression-support.patch > package/network/utils/nftables/patches/0001-nftables-add-fullcone-expression-support.patch
curl -s $mirror/openwrt/patch/firewall4/nftables/0002-nftables-add-brcm-fullconenat-support.patch > package/network/utils/nftables/patches/0002-nftables-add-brcm-fullconenat-support.patch

# FullCone module
git clone https://github.com/8688Add/nft-fullcone package/nft-fullcone
#git clone https://github.com/hubbylei/fullconenat-nft package/network/utils/fullconenat-nft

# IPv6 NAT
git clone https://github.com/sbwml/packages_new_nat6 package/nat6 -b openwrt-25.12

# natflow
merge_package https://github.com/QiuSimons/OpenWrt-Add OpenWrt-Add/openwrt-natflow

# luci-app-firewall
curl -s https://raw.githubusercontent.com/openwrt/luci/refs/heads/master/applications/luci-app-firewall/htdocs/luci-static/resources/view/firewall/zones.js > feeds/luci/applications/luci-app-firewall/htdocs/luci-static/resources/view/firewall/zones.js

# Patch Luci add nft_fullcone/bcm_fullcone & shortcut-fe & natflow & ipv6-nat & custom nft command option
pushd feeds/luci
    curl -s $mirror/openwrt/patch/firewall4/luci-25.12/0001-luci-app-firewall-add-nft-fullcone-and-bcm-fullcone-.patch | patch -p1
    curl -s $mirror/openwrt/patch/firewall4/luci-25.12/0002-luci-app-firewall-add-shortcut-fe-option.patch | patch -p1
    curl -s $mirror/openwrt/patch/firewall4/luci-25.12/0003-luci-app-firewall-add-ipv6-nat-option.patch | patch -p1
    curl -s $mirror/openwrt/patch/firewall4/luci-25.12/0004-luci-add-firewall-add-custom-nft-rule-support.patch | patch -p1
    curl -s $mirror/openwrt/patch/firewall4/luci-25.12/0005-luci-app-firewall-add-natflow-offload-support.patch | patch -p1
    curl -s $mirror/openwrt/patch/firewall4/luci-25.12/0006-luci-app-firewall-enable-hardware-offload-only-on-de.patch | patch -p1
    curl -s $mirror/openwrt/patch/firewall4/luci-25.12/0007-luci-app-firewall-add-fullcone6-option-for-nftables-.patch | patch -p1
popd

# kernel patch
# btf: silence btf module warning messages
#curl -s $mirror/openwrt/patch/kernel-6.12/btf/990-btf-silence-btf-module-warning-messages.patch > target/linux/generic/hack-6.12/990-btf-silence-btf-module-warning-messages.patch
# cpu model
#curl -s $mirror/openwrt/patch/kernel-6.12/arm64/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch > target/linux/generic/hack-6.12/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# fullcone
#curl -s $mirror/openwrt/patch/kernel-6.12/net/952-net-conntrack-events-support-multiple-registrant.patch > target/linux/generic/hack-6.12/952-net-conntrack-events-support-multiple-registrant.patch
# bcm-fullcone
#curl -s $mirror/openwrt/patch/kernel-6.12/net/982-add-bcm-fullcone-support.patch > target/linux/generic/hack-6.12/982-add-bcm-fullcone-support.patch
#curl -s $mirror/openwrt/patch/kernel-6.12/net/983-add-bcm-fullcone-nft_masq-support.patch > target/linux/generic/hack-6.12/983-add-bcm-fullcone-nft_masq-support.patch

# 修正部分从第三方仓库拉取的软件 Makefile 路径问题
#find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
#find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
#find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/rust\/rust-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/rust\/rust-package.mk/g' {}
#find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
#find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

# 移除luci-app-attendedsysupgrade
sed -i '18d' feeds/luci/collections/luci-nginx/Makefile
sed -i '17d' feeds/luci/collections/luci/Makefile
sed -i '16s/ \\$//' feeds/luci/collections/luci/Makefile

# 替换文件
#curl -fsSL https://raw.githubusercontent.com/0118Add/X86_64-Test/main/10_system.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
curl -fsSL https://raw.githubusercontent.com/0118Add/X86_64-Test/main/general/25_storage.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/25_storage.js
#sed -i 's/WireGuard/WiGd状态/g' feeds/luci/protocols/luci-proto-wireguard/root/usr/share/luci/menu.d/luci-proto-wireguard.json
#rm -rf feeds/packages/lang/ruby
#cp -rf $GITHUB_WORKSPACE/general/ruby feeds/packages/lang/ruby
#rm -rf feeds/packages/net/onionshare-cli
#sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

# comment out the following line to restore the full description
#sed -i '/# timezone/i grep -q '\''/tmp/sysinfo/model'\'' /etc/rc.local || sudo sed -i '\''/exit 0/i [ "$(cat /sys\\/class\\/dmi\\/id\\/sys_vendor 2>\\/dev\\/null)" = "Default string" ] \&\& echo "x86_64" > \\/tmp\\/sysinfo\\/model'\'' /etc/rc.local\n' package/default-settings/default/zzz-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI Master\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''\'\'', branch = '\''LuCI Master'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/default-settings/default/zzz-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-24.10\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI openwrt-24.10'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/default-settings/default/zzz-default-settings
#curl -fsSL https://raw.githubusercontent.com/0118Add/X86_64-Test/main/general/os-release > package/base-files/files/etc/os-release

./scripts/feeds update -i
./scripts/feeds install -a
