#!/bin/bash
#===============================================
# Description: DIY script part 2
# File name: diy-part2.sh
# Lisence: MIT
# By: BGG
#===============================================

echo "开始配置……"
echo "========================="

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

mirror="https://raw.githubusercontent.com/sbwml/r4s_build_script/refs/heads/master"
github="github.com"
gitea="git.cooluc.com"

# 修改主机名字（不能纯数字或者使用中文）
sed -i "s/hostname='.*'/hostname='OpenWrt'/g" package/base-files/files/bin/config_generate
#sed -i "s/OpenWrt /OPWRT/g" package/lean/default-settings/files/zzz-default-settings

# 加入作者信息
#sed -i "s/DISTRIB_DESCRIPTION='*.*'/DISTRIB_DESCRIPTION='OpenWrt-X86-$(date +%Y%m%d)'/g" package/lean/default-settings/files/zzz-default-settings   
#sed -i "s/DISTRIB_REVISION='*.*'/DISTRIB_REVISION=' BGG'/g" package/lean/default-settings/files/zzz-default-settings

# 修改默认IP
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# 修改型号
#sed -i 's/echo.*/echo "$vendor" > \/tmp\/sysinfo\/model/g' target/linux/x86/base-files/lib/preinit/01_sysinfo

# 修改版本为编译日期
#date_version=$(date +"%y.%m.%d")
#orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
#sed -i "s/${orig_version}/R${date_version}/g" package/lean/default-settings/files/zzz-default-settings

# 设置密码为空（安装固件时无需密码登陆，然后自己修改想要的密码）
#sed -i 's@.*CYXluq4wUazHjmCDBCqXF*@#&@g' package/lean/default-settings/files/zzz-default-settings

# 替换内核
sed -i 's/KERNEL_PATCHVER:=6.12/KERNEL_PATCHVER:=6.18/g' target/linux/x86/Makefile

# 内核替换 kernel xxx
#sed -i 's/LINUX_KERNEL_HASH-6.12.62 = 13e2c685ac8fab5dd992dd105732554dae514aef350c2a8c7418e7b74eb62c13/LINUX_KERNEL_HASH-6.12.55 = 328f8f4608a653063a5fd82d29b17163faab2825fa419fa85b961740a342fb9f/g' ./include/kernel-6.12
#sed -i 's/LINUX_VERSION-6.12 = .62/LINUX_VERSION-6.12 = .55/g' ./include/kernel-6.12

# 替换文件
#wget -O ./package/kernel/linux/modules/netsupport.mk https://raw.githubusercontent.com/0118Add/X86-N1-Actions/main/general/netsupport.mk
#wget -O ./package/lean/autocore/files/x86/index.htm https://raw.githubusercontent.com/0118Add/OpenWrt/main/images/index.htm

# 去除主页一串的LUCI版本号显示
#sed -i 's/distversion)%>/distversion)%><!--/g' package/lean/autocore/files/*/index.htm
#sed -i 's/luciversion)%>)/luciversion)%>)-->/g' package/lean/autocore/files/*/index.htm

# 修改概览里时间显示为中文数字
#sed -i 's/os.date()/os.date("%Y-%m-%d") .. " " .. translate(os.date("%A")) .. " " .. os.date("%X")/g' package/lean/autocore/files/x86/index.htm

# x86 型号只显示 CPU 型号
#sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}/g' package/lean/autocore/files/x86/autocore

# 添加温度显示
#sed -i 's/or "1"%>/or "1"%> ( <%=luci.sys.exec("expr `cat \/sys\/class\/thermal\/thermal_zone0\/temp` \/ 1000") or "?"%> \&#8451; ) /g' feeds/luci/modules/luci-mod-admin-full/luasrc/view/admin_status/index.htm

# 替换banner
#wget -O ./package/base-files/files/etc/banner https://raw.githubusercontent.com/0118Add/X86_64-Test/main/general/banner

# 修改默认主题
#sed -i 's/luci-theme-bootstrap/luci-theme-infinityfreedom/g' feeds/luci/collections/luci/Makefile

# 删除主题强制默认
#find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

# 修改连接数
sed -i 's/net.netfilter.nf_conntrack_max=.*/net.netfilter.nf_conntrack_max=65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf

# 修正连接数
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=165535' package/base-files/files/etc/sysctl.conf

# autocore
git clone --depth=1 -b openwrt-25.12 https://github.com/sbwml/autocore-arm package/autocore

# Default settings
rm -rf package/default-settings
git clone https://github.com/sbwml/default-settings package/default-settings

# golang 27.x
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 27.x feeds/packages/lang/golang

# 预编译 node
rm -rf feeds/packages/lang/node
git clone --depth=1 -b packages-25.12 https://github.com/sbwml/feeds_packages_lang_node-prebuilt feeds/packages/lang/node

# 移除重复软件包
rm -rf feeds/other/lean/autocore
rm -rf package/public/autocore
rm -rf package/public/autosamba
rm -rf package/network/utils/fullconenat-nft
rm -rf feeds/packages/net/{sing-box,v2ray-geodata,xray-core,zerotier}
rm -rf feeds/lienol/other/luci-app-diskman
#rm -rf feeds/lienol/other/luci-app-dockerman
rm -rf feeds/lienol/other/lean/luci-app-autoreboot
rm -rf feeds/lienol/other/lean/mt/luci-app-mtwifi
rm -rf feeds/lienol/other/lean/luci-app-mwan3helper
rm -rf feeds/lienol/other/lean/luci-app-turboacc
rm -rf feeds/lienol/other/lean/luci-app-zerotier
rm -rf feeds/luci/applications/luci-app-alist
rm -rf feeds/luci/applications/luci-app-dockerman
rm -rf feeds/luci/applications/luci-app-filemanager
rm -rf feeds/luci/applications/luci-app-mjpg-streamer
rm -rf feeds/luci/applications/luci-app-smartdns
rm -rf feeds/luci/applications/luci-app-ttyd
rm -rf feeds/luci/applications/luci-app-ramfree
rm -rf feeds/lienol/luci-app-ramfree
rm -rf target/linux/generic/hack-6.12/952-add-net-conntrack-events-support-multiple-registrant.patch
rm -rf target/linux/generic/hack-6.6/952-add-net-conntrack-events-support-multiple-registrant.patch

# 添加额外软件包
#git clone https://github.com/jerrykuku/lua-maxminddb package/lua-maxminddb
#git clone https://github.com/0118Add/luci-app-vssr package/luci-app-vssr
#git clone https://github.com/xiaorouji/openwrt-passwall package/passwall
#git clone -b main --single-branch https://github.com/xiaorouji/openwrt-passwall package/passwall-luci
#git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall
git_sparse_clone main https://github.com/Openwrt-Passwall/openwrt-passwall-packages sing-box v2ray-geodata xray-core
#git clone https://github.com/sbwml/openwrt_helloworld package/openwrt_helloworld
#git_sparse_clone main https://github.com/kiddin9/kwrt-packages coremark
#git clone https://github.com/xiaorouji/openwrt-passwall2 package/passwall2
#git clone https://github.com/sbwml/luci-app-alist.git package/alist
#git clone https://github.com/QiuSimons/luci-app-daed-next package/luci-app-daed-next
#git clone -b lede --single-branch https://github.com/lwb1978/luci-app-smartdns package/luci-app-smartdns
#git clone https://github.com/sirpdboy/netspeedtest.git package/netspeedtest
#git clone https://github.com/8688Add/luci-theme-argon-dark-mod.git package/luci-theme-argon-dark-mod
#git clone https://github.com/justice2001/luci-app-multi-frpc package/luci-app-multi-frpc
#git clone https://github.com/sirpdboy/luci-app-advanced.git package/luci-app-advanced
git clone -b dev --depth 1 https://github.com/vernesong/OpenClash package/OpenClash
#git clone https://github.com/EasyTier/luci-app-easytier package/luci-app-easytier
#git clone https://github.com/asvow/luci-app-tailscale  package/luci-app-tailscale
#git clone https://github.com/8688Add/luci-app-zerotier package/luci-app-zerotier
git clone https://github.com/sbwml/luci-app-filemanager package/luci-app-filemanager
git clone https://github.com/sirpdboy/luci-app-partexp package/luci-app-partexp
#git clone https://github.com/sirpdboy/luci-app-ddns-go package/luci-app-ddns-go
#git clone https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic package/luci-app-unblockneteasemusic
#git clone -b nekobox --depth 1 https://github.com/Thaolga/openwrt-nekobox package/nekobox
#git clone https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom package/luci-theme-infinityfreedom
#rm -rf feeds/luci/themes/luci-theme-argon
#rm -rf feeds/luci/themes/luci-theme-design
#git clone -b 18.06 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
#git clone https://github.com/gngpp/luci-theme-design package/luci-theme-design
#rm -rf feeds/packages/net/smartdns
#cp -rf ${GITHUB_WORKSPACE}/general/smartdns feeds/packages/net

# clashoo
git clone https://github.com/kenzok8/openwrt-clashoo package/clashoo

# homeproxy
git clone -b master --depth 1 https://github.com/szwjp/homeproxy package/luci-app-homeproxy
#git clone --depth 1 -b master https://github.com/fun200/homeproxy_plus package/luci-app-homeproxy
sed -i "s/ImmortalWrt/OpenWrt/g" package/luci-app-homeproxy/po/zh_Hans/homeproxy.po
sed -i "s/ImmortalWrt proxy/OpenWrt proxy/g" package/luci-app-homeproxy/htdocs/luci-static/resources/view/homeproxy/{client.js,server.js}

# mihomo
#git clone https://github.com/nikkinikki-org/OpenWrt-momo package/OpenWrt-momo
#git clone https://github.com/nikkinikki-org/OpenWrt-nikki  package/OpenWrt-nikki

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

# bpf-headers - 6.18
sed -ri "s/(PKG_PATCHVER:=)[^\"]*/\16.18/" package/kernel/bpf-headers/Makefile
curl -s $mirror/openwrt/patch/packages-patches/bpf-headers/900-fix-build.patch > package/kernel/bpf-headers/patches/900-fix-build.patch

# turboacc
#git clone https://github.com/chenmozhijin/turboacc package/turboacc
sed -i '/PKG_INSTALL:=/iPKG_FIXUP:=autoreconf' package/libs/libnftnl/Makefile
curl -sSL https://raw.githubusercontent.com/mufeng05/turboacc/main/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh
sed -i 's/Turbo ACC 网络加速/网络加速/g' package/turboacc/luci-app-turboacc/po/zh_Hans/turboacc.po

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
cp -rf immortalwrt-luci/applications/luci-app-ttyd feeds/luci/applications/luci-app-ttyd
ln -sf ../../../feeds/luci/applications/luci-app-ttyd ./package/feeds/luci/luci-app-ttyd
cp -rf immortalwrt-luci/applications/luci-app-unblockneteasemusic feeds/luci/applications/luci-app-unblockneteasemusic
ln -sf ../../../feeds/luci/applications/luci-app-unblockneteasemusic ./package/feeds/luci/luci-app-unblockneteasemusic
#cp -rf immortalwrt-luci/applications/luci-app-zerotier feeds/luci/applications/luci-app-zerotier
#ln -sf ../../../feeds/luci/applications/luci-app-zerotier ./package/feeds/luci/luci-app-zerotier
git clone --depth=1 -b openwrt-25.12 https://github.com/immortalwrt/packages.git immortalwrt-packages
cp -rf immortalwrt-packages/net/msd_lite feeds/packages/net/msd_lite
ln -sf ../../../feeds/packages/net/msd_lite ./package/feeds/packages/msd_lite
#cp -rf immortalwrt-packages/net/sing-box feeds/packages/net/sing-box
#ln -sf ../../../feeds/packages/net/sing-box ./package/feeds/packages/sing-box
#cp -rf immortalwrt-packages/net/zerotier feeds/packages/net/zerotier
#ln -sf ../../../feeds/packages/net/zerotier ./package/feeds/packages/zerotier
#sed -i "s/ImmortalWrt/OpenWrt/g" feeds/luci/applications/luci-app-homeproxy/po/zh_Hans/homeproxy.po
#sed -i "s/ImmortalWrt proxy/OpenWrt proxy/g" feeds/luci/applications/luci-app-homeproxy/htdocs/luci-static/resources/view/homeproxy/{client.js,server.js}

# Dockerman
#git clone https://github.com/sbwml/luci-app-dockerman package/luci-app-dockerman
#sed -i 's/"admin/"admin\/services/g' package/luci-app-dockerman/root/usr/share/luci/menu.d/luci-app-dockerman.json

# Realtek Ethernet driver - R8168 & R8125 & R8126 & R8152 & R8101 & r8127
rm -rf package/kernel/{r8168,r8101,r8125,r8126,r8127}
git_sparse_clone master https://github.com/8688Add/openwrt_pkgs package_kernel_r8101 package_kernel_r8125 package_kernel_r8126 package_kernel_r8127 package_kernel_r8168
#git clone https://github.com/sbwml/package_kernel_r8168 package/kernel/r8168
#git clone https://github.com/sbwml/package_kernel_r8101 package/kernel/r8101
#git clone https://github.com/sbwml/package_kernel_r8125 package/kernel/r8125
#git clone https://github.com/sbwml/package_kernel_r8126 package/kernel/r8126
#git clone https://github.com/sbwml/package_kernel_r8127 package/kernel/r8127

# 修改插件名字（修改名字后不知道会不会对插件功能有影响，自己多测试）
#sed -i 's/Argon 主题设置/Argon设置/g' feeds/luci/applications/luci-app-argon-config/po/zh-cn/argon-config.po
#sed -i 's/Design 主题设置/Design设置/g' feeds/luci/applications/luci-app-design-config/po/zh-cn/design-config.po
#sed -i 's/CPU 性能优化调节/性能优化/g' feeds/luci/applications/luci-app-cpufreq/po/zh-cn/cpufreq.po
#sed -i 's/一键分区扩容/分区扩容/g' package/luci-app-partexp/po/zh-cn/partexp.po
#sed -i 's/"管理权"/"改密码"/g' feeds/luci/modules/luci-base/po/zh-cn/base.po
#sed -i 's/TTYD 终端/命令行/g' feeds/luci/applications/luci-app-ttyd/po/zh-cn/terminal.po
#sed -i 's/ShadowSocksR Plus+/SSR Plus+/g' package/helloworld/luci-app-ssr-plus/luasrc/controller/shadowsocksr.lua
#sed -i 's/msgstr "KMS 服务器"/msgstr "KMS激活"/g' feeds/luci/applications/luci-app-vlmcsd/po/zh-cn/vlmcsd.po
#sed -i 's/msgstr "UPnP"/msgstr "UPnP设置"/g' feeds/luci/applications/luci-app-upnp/po/zh-cn/upnp.po
#sed -i 's/Frp 内网穿透/内网穿透/g' feeds/luci/applications/luci-app-frpc/po/zh-cn/frp.po
#sed -i 's/Frpc内网穿透/内网穿透/g' package/luci-app-multi-frpc/po/zh-cn/frp.po
#sed -i 's/NekoClash/Clash/g' package/nekoclash/luci-app-nekoclash/luasrc/controller/neko.lua
sed -i 's/解除网易云音乐播放限制/音乐解锁/g' feeds/luci/applications/luci-app-unblockneteasemusic/root/usr/share/luci/menu.d/luci-app-unblockneteasemusic.json
#sed -i 's/"阿里云盘 WebDAV"/"阿里云盘"/g' package/aliyundrive-webdav/openwrt/luci-app-aliyundrive-webdav/po/zh-cn/aliyundrive-webdav.po
#sed -i 's/V2ray 服务器/V2ray服务/g' feeds/luci/applications/luci-app-v2ray-server/po/zh-cn/v2ray_server.po
#sed -i 's/SoftEther VPN 服务器/SoftEther/g' feeds/luci/applications/luci-app-softethervpn/po/zh-cn/softethervpn.po
#sed -i 's/firstchild(), "VPN"/firstchild(), "GFW"/g' feeds/luci/applications/luci-app-softethervpn/luasrc/controller/softethervpn.lua
#sed -i 's/IPSec VPN 服务器/IPSec VPN/g' feeds/luci/applications/luci-app-ipsec-vpnd/po/zh-cn/ipsec.po
#sed -i 's/WireGuard 状态/WiGd状态/g' feeds/luci/applications/luci-app-wireguard/po/zh-cn/wireguard.po
#sed -i 's/Turbo ACC 网络加速/网络加速/g' package/luci-app-turboacc/po/zh-cn/turboacc.po

# 去掉ssr+中shadowsocksr-libev的libopenssl-legacy依赖支持
#sed -i 's/ +libopenssl-legacy//g' package/helloworld/shadowsocksr-libev/Makefile

# rust版本以免编译失败
#sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

# 调整 Dockerman 到 服务 菜单
sed -i 's/"admin",/"admin","services",/g' feeds/lienol/other/luci-app-dockerman/luasrc/controller/*.lua
sed -i 's/"admin/"admin\/services/g' feeds/lienol/other/luci-app-dockerman/luasrc/model/*.lua
sed -i 's/"admin/"admin\/services/g' feeds/lienol/other/luci-app-dockerman/luasrc/model/cbi/dockerman/*.lua
sed -i 's/"admin/"admin\/services/g' feeds/lienol/other/luci-app-dockerman/luasrc/view/dockerman/*.htm
sed -i 's/"admin/"admin\/services/g' feeds/lienol/other/luci-app-dockerman/luasrc/view/dockerman/cbi/*.htm

# 调整 tailscale zerotier 到 服务 菜单
#sed -i 's/vpn/services/g' feeds/luci/applications/luci-app-zerotier/root/usr/share/luci/menu.d/luci-app-zerotier.json
#sed -i 's/vpn/services/g' package/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json

# 调整 bypass 到 GFW 菜单
#sed -i 's/services/vpn/g' package/luci-app-bypass/luasrc/controller/*.lua
#sed -i 's/services/vpn/g' package/luci-app-bypass/luasrc/model/cbi/bypass/*.lua
#sed -i 's/services/vpn/g' package/luci-app-bypass/luasrc/view/bypass/*.htm

# 调整 SSRP 到 GFW 菜单
#sed -i 's/services/vpn/g' package/helloworld/luci-app-ssr-plus/luasrc/controller/*.lua
#sed -i 's/services/vpn/g' package/helloworld/luci-app-ssr-plus/luasrc/model/cbi/shadowsocksr/*.lua
#sed -i 's/services/vpn/g' package/helloworld/luci-app-ssr-plus/luasrc/view/shadowsocksr/*.htm

# 调整 Pass Wall 到 GFW 菜单
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/controller/*.lua
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/model/cbi/passwall/client/*.lua
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/model/cbi/passwall/server/*.lua
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/passwall/*.lua
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/view/passwall/app_update/*.htm
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/view/passwall/global/*.htm
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/view/passwall/haproxy/*.htm
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/view/passwall/log/*.htm
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/view/passwall/node_list/*.htm
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/view/passwall/rule/*.htm
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/view/passwall/server/*.htm
#sed -i 's/services/vpn/g' package/passwall/luci-app-passwall/luasrc/view/passwall/socks_auto_switch/*.htm

# 调整 Pass Wall 2 到 GFW 菜单
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/controller/*.lua
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/model/cbi/passwall2/client/*.lua
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/model/cbi/passwall2/server/*.lua
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/passwall2/*.lua
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/view/passwall2/app_update/*.htm
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/view/passwall2/global/*.htm
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/view/passwall2/haproxy/*.htm
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/view/passwall2/log/*.htm
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/view/passwall2/node_list/*.htm
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/view/passwall2/rule/*.htm
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/view/passwall2/server/*.htm
#sed -i 's/services/vpn/g' package/passwall2/luci-app-passwall2/luasrc/view/passwall2/socks_auto_switch/*.htm

# 调整 Hello World 到 GFW 菜单
#sed -i 's/services/vpn/g' package/luci-app-vssr/luasrc/controller/*.lua
#sed -i 's/services/vpn/g' package/luci-app-vssr/luasrc/model/cbi/vssr/*.lua
#sed -i 's/services/vpn/g' package/luci-app-vssr/luasrc/view/vssr/*.htm

# 调整 Open Clash 到 GFW 菜单
#sed -i 's/services/vpn/g' package/luci-app-openclash/luci-app-openclash/luasrc/controller/*.lua
#sed -i 's/services/vpn/g' package/luci-app-openclash/luci-app-openclash/luasrc/*.lua
#sed -i 's/services/vpn/g' package/luci-app-openclash/luci-app-openclash/luasrc/model/cbi/openclash/*.lua
#sed -i 's/services/vpn/g' package/luci-app-openclash/luci-app-openclash/luasrc/view/openclash/*.htm

# 自定义默认配置
#curl -fsSL https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/x86/diy/x86_lede/10_system.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
curl -fsSL https://raw.githubusercontent.com/0118Add/X86-Actions/main/general/25_storage.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/25_storage.js
#curl -fsSL https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/immortalwrt/29_ports.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/29_ports.js

# comment out the following line to restore the full description
#sed -i '/# timezone/i grep -q '\''/tmp/sysinfo/model'\'' /etc/rc.local || sudo sed -i '\''/exit 0/i [ "$(cat /sys\\/class\\/dmi\\/id\\/sys_vendor 2>\\/dev\\/null)" = "Default string" ] \&\& echo "x86_64" > \\/tmp\\/sysinfo\\/model'\'' /etc/rc.local\n' package/default-settings/default/zzz-default-settings
sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-25.12\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''\'\'', branch = '\''LuCI openwrt-25.12'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/default-settings/default/zzz-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-25.12\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI openwrt-25.12'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/default-settings/default/zzz-default-settings
curl -fsSL https://raw.githubusercontent.com/0118Add/X86-N1-Actions/main/scripts/release-os > package/base-files/files/etc/os-release

rm -rf feeds/packages/admin/zabbix
rm -rf feeds/packages/net/onionshare-cli

./scripts/feeds update -i
./scripts/feeds install -a
