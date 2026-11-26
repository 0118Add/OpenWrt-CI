#!/bin/bash

# 1. 修改默认 IP
sed -i '/lan)/s/192\.168\.[0-9.]*/10.0.0.1/' package/base-files/files/bin/config_generate

# 修改连接数
sed -i 's/net.netfilter.nf_conntrack_max=.*/net.netfilter.nf_conntrack_max=65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# 修正连接数
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=165535' package/base-files/files/etc/sysctl.conf

# 2.移除要替换的包
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-dockerman
rm -rf feeds/luci/applications/luci-app-filemanager
rm -rf feeds/luci/applications/luci-app-mjpg-streamer
rm -rf feeds/luci/applications/luci-app-zerotier
rm -rf feeds/packages/utils/coremark
rm -rf feeds/packages/lang/golang
rm -rf feeds/packages/lang/node
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls}
#rm -rf feeds/luci/applications/luci-app-netdata

# 3. 增强版稀疏克隆函数 (参数1是分支名, 参数2是仓库地址, 参数3是子目录，同一个仓库下载多个文件夹直接在后面跟文件名或路径，空格分开)
function git_sparse_clone() {
  local branch=""
  local repourl=""
  local sub_paths=()
  local repodir=""

  # 1. 智能参数解析
  if [[ "$1" == http* ]]; then
    # 情况 A: 第一个参数是 URL (可能是网页链接或纯仓库地址)
    if [[ "$1" == *"tree/"* ]]; then
      # 自动解析 GitHub 网页格式: .../tree/分支/路径
      repourl="${1%/tree/*}"
      local rest="${1#*/tree/}"
      branch="${rest%%/*}"
      sub_paths=("${rest#*/}")
      echo ">> 检测到网页 URL，自动解析分支: [$branch], 路径: [${sub_paths[0]}]"
    else
      # 纯仓库地址，尝试使用第二个参数作为分支，默认为 main
      repourl="$1"
      branch="${2:-main}"
      shift 2
      sub_paths=("$@")
      echo ">> 检测到纯仓库地址，使用分支: [$branch]"
    fi
  else
    # 情况 B: 兼容你原始的代码格式 (参数1:分支 参数2:地址 参数3+:路径)
    branch="$1"
    repourl="$2"
    shift 2
    sub_paths=("$@")
    echo ">> 使用原始传参模式，分支: [$branch]"
  fi

  # 2. 准备克隆环境
  # 使用 basename 处理 .git 后缀，防止 cd 失败
  repodir=$(basename "$repourl" .git)
  
  # 3. 执行极速克隆 (Blob 过滤 + 稀疏模式)
  git clone --depth=1 -b "$branch" --single-branch --filter=blob:none --sparse "$repourl" "$repodir"
  if [ $? -ne 0 ]; then
    echo "错误: 克隆失败，请检查 URL 或分支名。"
    return 1
  fi

  cd "$repodir" || return

  # 4. 如果没有指定子路径，默认拉取整个仓库内容
  if [ ${#sub_paths[@]} -eq 0 ]; then
    echo ">> 未指定子路径，拉取全量代码..."
    git sparse-checkout disable
  else
    echo ">> 正在提取指定目录: ${sub_paths[*]}"
    git sparse-checkout set "${sub_paths[@]}"
  fi

  # 5. 搬运到 ../package/
  mkdir -p ../package/
  for sub in "${sub_paths[@]}"; do
    if [ -d "$sub" ]; then
      local target_name=$(basename "$sub")
      local target="../package/$target_name"
      [ -d "$target" ] && rm -rf "$target"
      mv -f "$sub" ../package/
      echo "   [已完成] $target_name"
    fi
  done

  # 6. 清理
  cd .. && rm -rf "$repodir"
  echo ">> 任务结束。"
}

# autoCore
git clone https://github.com/sbwml/autocore-arm -b openwrt-25.12 package/autocore

# Default settings
git_sparse_clone master https://github.com/8688Add/openwrt_pkgs coremark default-settings

# golang 27.x
git clone https://github.com/sbwml/packages_lang_golang -b 27.x feeds/packages/lang/golang

# 预编译 node
git clone https://github.com/sbwml/feeds_packages_lang_node feeds/packages/lang/node -b packages-25.12

# OpenClash
git clone -b dev --depth 1 https://github.com/vernesong/OpenClash package/OpenClash

# Shared for PassWall and ShadowsocksR Plus+
#git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages -b main
git_sparse_clone main https://github.com/Openwrt-Passwall/openwrt-passwall-packages v2ray-geodata sing-box xray-core

# homeproxy
#git clone --depth 1 -b master https://github.com/fun200/homeproxy_plus package/luci-app-homeproxy
git clone --depth 1 -b master https://github.com/sjnhnp/homeproxy package/luci-app-homeproxy
#merge_package https://github.com/sbwml/openwrt_helloworld openwrt_helloworld/luci-app-homeproxy
#merge_package https://github.com/VIKINGYFY/packages packages/luci-app-homeproxy
#merge_package https://github.com/VIKINGYFY/packages packages/sing-box
sed -i "s/ImmortalWrt/OpenWrt/g" package/luci-app-homeproxy/po/zh_Hans/homeproxy.po
sed -i "s/ImmortalWrt proxy/OpenWrt proxy/g" package/luci-app-homeproxy/htdocs/luci-static/resources/view/homeproxy/{client.js,server.js}

# mihomo
#git clone https://github.com/nikkinikki-org/OpenWrt-nikki package/OpenWrt-nikki
#git clone https://github.com/nikkinikki-org/OpenWrt-momo package/OpenWrt-momo

# dae daed
#git clone https://github.com/kenzok8/openwrt-daede package/daede
#git clone https://github.com/kenzok8/openwrt-clashoo package/clashoo
#git clone -b kix --depth 1 https://github.com/QiuSimons/luci-app-dae package/dae
git clone -b master --depth 1 https://github.com/QiuSimons/luci-app-honk package/honk
git clone https://github.com/QiuSimons/vmlinux-btf package/vmlinux-btf
#sed -i 's/PKG_VERSION:=.*/PKG_VERSION:=2026.06.14/g' package/daed/daed/Makefile
#sed -i 's/DAED_VERSION:=.*/DAED_VERSION:=daed-4d6a433/g' package/daed/daed/Makefile
#sed -i 's/WING_VERSION:=.*/WING_VERSION:=wing-dc50308/g' package/daed/daed/Makefile
#sed -i 's/CORE_VERSION:=.*/CORE_VERSION:=core-5a51cc7/g' package/daed/daed/Makefile
#sed -i 's/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=4d6a43331f2f6e25961935b9e7ac09a7568bb2b4/g' package/daed/daed/Makefile

# ttyd
sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i '3 a\\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

# partexp
git clone https://github.com/sirpdboy/luci-app-partexp package/luci-app-partexp

# luci-app-filemanager
git clone https://github.com/sbwml/luci-app-filemanager package/luci-app-filemanager

# tailscale
#git clone https://github.com/Jaykwok2999/luci-app-tailscale  package/luci-app-tailscale
#sed -i 's/vpn/services/g' package/luci-app-tailscale/root/usr/share/luci/menu.d/luci-app-tailscale.json

# zerotier
git clone https://github.com/8688Add/luci-app-zerotier package/luci-app-zerotier
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
git clone https://github.com/sbwml/luci-app-dockerman feeds/luci/applications/luci-app-dockerman
sed -i 's/"admin/"admin\/services/g' feeds/luci/applications/luci-app-dockerman/root/usr/share/luci/menu.d/luci-app-dockerman.json
#sed -i 's/"admin",/"admin","services",/g' package/dockerman/applications/luci-app-dockerman/luasrc/controller/*.lua
#sed -i 's/"admin/"admin\/services/g' package/dockerman/applications/luci-app-dockerman/luasrc/model/*.lua
#sed -i 's/"admin/"admin\/services/g' package/dockerman/applications/luci-app-dockerman/luasrc/model/cbi/dockerman/*.lua
#sed -i 's/"admin/"admin\/services/g' package/dockerman/applications/luci-app-dockerman/luasrc/view/dockerman/*.htm
#sed -i 's/"admin/"admin\/services/g' package/dockerman/applications/luci-app-dockerman/luasrc/view/dockerman/cbi/*.htm

# turboacc
#git clone https://github.com/chenmozhijin/turboacc package/turboacc
#git clone https://github.com/QiuSimons/FlowCone package/FlowCone
#curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/main/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh
sed -i '/PKG_INSTALL:=/iPKG_FIXUP:=autoreconf' package/libs/libnftnl/Makefile
#curl -sSL https://raw.githubusercontent.com/mufeng05/openwrt-sonic-fullcone/master/add_sonic_fullcone.sh -o add_sonic_fullcone.sh && bash add_sonic_fullcone.sh
curl -sSL https://raw.githubusercontent.com/mufeng05/turboacc/main/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh
sed -i 's/Turbo ACC 网络加速/网络加速/g' package/turboacc/luci-app-turboacc/po/zh_Hans/turboacc.po

# 移除luci-app-attendedsysupgrade
sed -i '18d' feeds/luci/collections/luci-nginx/Makefile
sed -i '17d' feeds/luci/collections/luci/Makefile
sed -i '16s/ \\$//' feeds/luci/collections/luci/Makefile

# 替换文件
#curl -fsSL https://raw.githubusercontent.com/0118Add/X86_64-Test/main/10_system.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
curl -fsSL https://raw.githubusercontent.com/0118Add/X86_64-Test/main/general/25_storage.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/25_storage.js
curl -fsSL https://raw.githubusercontent.com/immortalwrt/luci/master/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/29_ports.js > ./package/autocore/files/generic/29_ports.js
#sed -i 's/WireGuard/WiGd状态/g' feeds/luci/protocols/luci-proto-wireguard/root/usr/share/luci/menu.d/luci-proto-wireguard.json
#rm -rf feeds/packages/net/onionshare-cli
rm -rf feeds/luci/applications/luci-app-advanced-reboot

# rust
#wget https://github.com/rust-lang/rust/commit/cdae267.patch -O feeds/packages/lang/rust/patches/cdae267.patch
#sed -i 's/--set=llvm\.download-ci-llvm=true/--set=llvm.download-ci-llvm=false/' feeds/packages/lang/rust/Makefile

# comment out the following line to restore the full description
#sed -i '/# timezone/i grep -q '\''/tmp/sysinfo/model'\'' /etc/rc.local || sudo sed -i '\''/exit 0/i [ "$(cat /sys\\/class\\/dmi\\/id\\/sys_vendor 2>\\/dev\\/null)" = "Default string" ] \&\& echo "x86_64" > \\/tmp\\/sysinfo\\/model'\'' /etc/rc.local\n' package/default-settings/default/zzz-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-25.12\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''\'\'', branch = '\''LuCI openwrt-25.12'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/default-settings/default/zzz-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-24.10\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI openwrt-24.10'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/default-settings/default/zzz-default-settings
#curl -fsSL https://raw.githubusercontent.com/0118Add/X86_64-Test/main/patch/release-os > package/base-files/files/etc/os-release

./scripts/feeds update -i
./scripts/feeds install -a
