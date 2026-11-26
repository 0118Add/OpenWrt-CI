#!/bin/bash

mirror="https://raw.githubusercontent.com/sbwml/r4s_build_script/refs/heads/master"
github="github.com"
gitea="git.cooluc.com"

# 1. 修改默认 IP
sed -i '/lan)/s/192\.168\.[0-9.]*/10.0.0.1/' package/base-files/files/bin/config_generate

# 替换内核
sed -i 's/KERNEL_PATCHVER:=6.12/KERNEL_PATCHVER:=6.18/g' target/linux/x86/Makefile

# 修改连接数
sed -i 's/net.netfilter.nf_conntrack_max=.*/net.netfilter.nf_conntrack_max=65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# 修正连接数
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=165535' package/base-files/files/etc/sysctl.conf

# 2.移除要替换的包
rm -rf feeds/other/lean/autocore
rm -rf package/public/autocore
rm -rf package/public/autosamba
rm -rf package/network/utils/fullconenat-nft
rm -rf feeds/packages/net/{sing-box,v2ray-geodata,xray-core,zerotier}
rm -rf feeds/lienol/other/luci-app-diskman
#rm -rf feeds/lienol/other/luci-app-dockerman
rm -rf feeds/lienol/other/lean/mt/luci-app-mtwifi
rm -rf feeds/lienol/other/lean/luci-app-mwan3helper
rm -rf feeds/lienol/other/lean/luci-app-autoreboot
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

# autocore
git clone --depth=1 -b openwrt-25.12 https://github.com/sbwml/autocore-arm package/autocore
wget -O ./package/autocore/files/generic/10_system.js https://raw.githubusercontent.com/0118Add/X86-Actions/main/scripts/10_system.js

# Default settings
rm -rf package/default-settings
rm -rf feeds/packages/utils/coremark
git clone https://github.com/sbwml/default-settings package/default-settings
git_sparse_clone master https://github.com/8688Add/openwrt_pkgs coremark
wget -O ./package/default-settings/default/zzz-default-settings https://raw.githubusercontent.com/0118Add/X86-Actions/main/general/zzz-default-settings

# golang 26.x
rm -rf feeds/packages/lang/golang
git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# 预编译 node
rm -rf feeds/packages/lang/node
git clone --depth=1 -b packages-25.12 https://github.com/sbwml/feeds_packages_lang_node-prebuilt feeds/packages/lang/node

# 添加额外软件包
#git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall
git_sparse_clone v5 https://github.com/sbwml/openwrt_helloworld sing-box luci-app-homeproxy
git_sparse_clone main https://github.com/Openwrt-Passwall/openwrt-passwall-packages v2ray-geodata xray-core
git clone -b dev --depth 1 https://github.com/vernesong/OpenClash package/OpenClash
git clone https://github.com/sbwml/luci-app-filemanager package/luci-app-filemanager
git clone https://github.com/sirpdboy/luci-app-partexp package/luci-app-partexp

# homeproxy
#git clone --depth 1 -b master https://github.com/fun200/homeproxy_plus package/luci-app-homeproxy
#git_sparse_clone main https://github.com/VIKINGYFY/packages sing-box luci-app-homeproxy
sed -i "s/ImmortalWrt/OpenWrt/g" package/luci-app-homeproxy/po/zh_Hans/homeproxy.po
sed -i "s/ImmortalWrt proxy/OpenWrt proxy/g" package/luci-app-homeproxy/htdocs/luci-static/resources/view/homeproxy/{client.js,server.js}

# mihomo
#git clone https://github.com/nikkinikki-org/OpenWrt-momo package/OpenWrt-momo
#git clone https://github.com/nikkinikki-org/OpenWrt-nikki  package/OpenWrt-nikki
#git clone -b main --depth 1 https://github.com/YiXuanZX/OpenWrt-nikki package/OpenWrt-nikki

# dae daed
#git clone https://github.com/kenzok8/openwrt-daede package/daede
#git clone https://github.com/kenzok8/openwrt-clashoo package/clashoo
git clone -b master --depth 1 https://github.com/QiuSimons/luci-app-honk package/honk
#git clone -b kix --depth 1 https://github.com/QiuSimons/luci-app-dae package/dae
#git clone -b kix --depth 1 https://github.com/QiuSimons/luci-app-daed package/daed
git clone https://github.com/kenzok8/vmlinux-btf package/vmlinux-btf
#sed -i 's/PKG_VERSION:=.*/PKG_VERSION:=2026.06.14/g' package/daed/daed/Makefile
#sed -i 's/DAED_VERSION:=.*/DAED_VERSION:=daed-4d6a433/g' package/daed/daed/Makefile
#sed -i 's/WING_VERSION:=.*/WING_VERSION:=wing-dc50308/g' package/daed/daed/Makefile
#sed -i 's/CORE_VERSION:=.*/CORE_VERSION:=core-5a51cc7/g' package/daed/daed/Makefile
#sed -i 's/PKG_SOURCE_VERSION:=.*/PKG_SOURCE_VERSION:=4d6a43331f2f6e25961935b9e7ac09a7568bb2b4/g' package/daed/daed/Makefile

# bpf-headers - 6.18
sed -ri "s/(PKG_PATCHVER:=)[^\"]*/\16.18/" package/kernel/bpf-headers/Makefile
curl -s $mirror/openwrt/patch/packages-patches/bpf-headers/900-fix-build.patch > package/kernel/bpf-headers/patches/900-fix-build.patch

# turboacc
#git clone https://github.com/chenmozhijin/turboacc package/turboacc
#sed -i '/PKG_INSTALL:=/iPKG_FIXUP:=autoreconf' package/libs/libnftnl/Makefile
#curl -sSL https://raw.githubusercontent.com/mufeng05/turboacc/main/add_turboacc.sh -o add_turboacc.sh && bash add_turboacc.sh
#sed -i 's/Turbo ACC 网络加速/网络加速/g' package/turboacc/luci-app-turboacc/po/zh_Hans/turboacc.po

# 克隆lean-luci仓库
git clone --depth=1 -b openwrt-25.12 https://github.com/coolsnowwolf/luci lean-luci
cp -rf lean-luci/applications/luci-app-oui feeds/luci/applications/luci-app-oui
ln -sf ../../../feeds/luci/applications/luci-app-oui ./package/feeds/luci/luci-app-oui

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

# ttyd
#sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i '3 a\\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

# Dockerman
#git clone https://github.com/sbwml/luci-app-dockerman feeds/luci/applications/luci-app-dockerman
#sed -i 's/"admin/"admin\/services/g' feeds/luci/applications/luci-app-dockerman/root/usr/share/luci/menu.d/luci-app-dockerman.json

# Realtek Ethernet driver - R8168 & R8125 & R8126 & R8152 & R8101 & r8127
rm -rf package/kernel/{r8168,r8101,r8125,r8126,r8127}
git_sparse_clone master https://github.com/8688Add/openwrt_pkgs package_kernel_r8101 package_kernel_r8125 package_kernel_r8126 package_kernel_r8127 package_kernel_r8168

# Shortcut Forwarding Engine
git clone https://github.com/xianren78/shortcut-fe package/new/shortcut-fe

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
rm -rf package/network/utils/fullconenat-nft
git clone https://github.com/xianren78/nft-fullcone package/new/nft-fullcone

# IPv6 NAT
git clone https://github.com/sbwml/packages_new_nat6 package/new/nat6 -b openwrt-25.12

# natflow
git clone https://github.com/sbwml/package_new_natflow package/new/natflow

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
curl -s $mirror/openwrt/patch/kernel-6.18/btf/990-btf-silence-btf-module-warning-messages.patch > target/linux/generic/hack-6.18/990-btf-silence-btf-module-warning-messages.patch
# cpu model
curl -s $mirror/openwrt/patch/kernel-6.18/arm64/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch > target/linux/generic/hack-6.18/312-arm64-cpuinfo-Add-model-name-in-proc-cpuinfo-for-64bit-ta.patch
# bcm-fullcone
curl -s $mirror/openwrt/patch/kernel-6.18/net/982-add-bcm-fullcone-support.patch > target/linux/generic/hack-6.18/982-add-bcm-fullcone-support.patch
curl -s $mirror/openwrt/patch/kernel-6.18/net/983-add-bcm-fullcone-nft_masq-support.patch > target/linux/generic/hack-6.18/983-add-bcm-fullcone-nft_masq-support.patch
# shortcut-fe
curl -s $mirror/openwrt/patch/kernel-6.18/net/601-netfilter-export-udp_get_timeouts-function.patch > target/linux/generic/hack-6.18/601-netfilter-export-udp_get_timeouts-function.patch
curl -s $mirror/openwrt/patch/kernel-6.18/net/952-net-conntrack-events-support-multiple-registrant.patch > target/linux/generic/hack-6.18/952-net-conntrack-events-support-multiple-registrant.patch
curl -s $mirror/openwrt/patch/kernel-6.18/net/953-net-patch-linux-kernel-to-support-shortcut-fe.patch > target/linux/generic/hack-6.18/953-net-patch-linux-kernel-to-support-shortcut-fe.patch

# nat46
mkdir -p package/kernel/nat46/patches
curl -s $mirror/openwrt/patch/packages-patches/nat46/102-fix-build-with-kernel-6.18.patch > package/kernel/nat46/patches/102-fix-build-with-kernel-6.18.patch

# 修改插件名字（修改名字后不知道会不会对插件功能有影响，自己多测试）
sed -i 's/解除网易云音乐播放限制/音乐解锁/g' feeds/luci/applications/luci-app-unblockneteasemusic/root/usr/share/luci/menu.d/luci-app-unblockneteasemusic.json

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

# 自定义默认配置
#curl -fsSL https://raw.githubusercontent.com/0118Add/X86-Actions/main/scripts/10_system.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
curl -fsSL https://raw.githubusercontent.com/0118Add/X86-Actions/main/general/25_storage.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/25_storage.js
#curl -fsSL https://raw.githubusercontent.com/0118Add/Openwrt-CI/main/immortalwrt/29_ports.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/29_ports.js
curl -fsSL https://raw.githubusercontent.com/immortalwrt/luci/master/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/29_ports.js > ./package/autocore/files/generic/29_ports.js

# comment out the following line to restore the full description
#sed -i '/# timezone/i grep -q '\''/tmp/sysinfo/model'\'' /etc/rc.local || sudo sed -i '\''/exit 0/i [ "$(cat /sys\\/class\\/dmi\\/id\\/sys_vendor 2>\\/dev\\/null)" = "Default string" ] \&\& echo "QEMU Standard PC" > \\/tmp\\/sysinfo\\/model'\'' /etc/rc.local\n' package/default-settings/default/zzz-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-25.12\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''\'\'', branch = '\''LuCI openwrt-25.12'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/default-settings/default/zzz-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI openwrt-25.12\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"v'$(date +%Y%m%d)'\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''v'$(date +%Y%m%d)'\'\'', branch = '\''LuCI openwrt-25.12'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/default-settings/default/zzz-default-settings
#sed -i '/# timezone/i sed -i "s/\\(DISTRIB_DESCRIPTION=\\).*/\\1'\''OpenWrt $(sed -n "s/DISTRIB_DESCRIPTION='\''OpenWrt \\([^ ]*\\) .*/\\1/p" /etc/openwrt_release)'\'',/" /etc/openwrt_release\nsource /etc/openwrt_release \&\& sed -i -e "s/distversion\\s=\\s\\".*\\"/distversion = \\"$DISTRIB_ID $DISTRIB_RELEASE ($DISTRIB_REVISION)\\"/g" -e '\''s/distname    = .*$/distname    = ""/g'\'' /usr/lib/lua/luci/version.lua\nsed -i "s/luciname    = \\".*\\"/luciname    = \\"LuCI (HEAD detached at 128a7812) branch 26.180.75667~128a788\\"/g" /usr/lib/lua/luci/version.lua\nsed -i "s/luciversion = \\".*\\"/luciversion = \\"\\"/g" /usr/lib/lua/luci/version.lua\necho "export const revision = '\''\'\'', branch = '\''LuCI (HEAD detached at 128a7812) branch 26.180.75667~128a788'\'';" > /usr/share/ucode/luci/version.uc\n/etc/init.d/rpcd restart\n' package/default-settings/default/zzz-default-settings
curl -fsSL https://raw.githubusercontent.com/0118Add/X86_64-Test/main/general/release > package/base-files/files/etc/os-release

rm -rf feeds/packages/admin/zabbix
rm -rf feeds/packages/net/onionshare-cli

./scripts/feeds update -i
./scripts/feeds install -a
