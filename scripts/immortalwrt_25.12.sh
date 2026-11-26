#!/bin/bash

# 1. 修改默认 IP
sed -i '/lan)/s/192\.168\.[0-9.]*/10.0.0.1/' package/base-files/files/bin/config_generate

# 修改连接数
sed -i 's/net.netfilter.nf_conntrack_max=.*/net.netfilter.nf_conntrack_max=65535/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
# 修正连接数
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=165535' package/base-files/files/etc/sysctl.conf

# 2.移除要替换的包
rm -rf package/emortal/autocore
rm -rf package/emortal/automount
rm -rf package/emortal/default-settings
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf feeds/luci/applications/luci-app-dockerman
#rm -rf feeds/luci/applications/luci-app-homeproxy
rm -rf feeds/luci/applications/luci-app-openclash
rm -rf feeds/luci/applications/luci-app-microsocks
rm -rf feeds/luci/applications/luci-app-passwall
rm -rf feeds/luci/applications/luci-app-dae
rm -rf feeds/packages/net/dae
rm -rf feeds/luci/applications/luci-app-daed
rm -rf feeds/packages/net/daed
rm -rf feeds/packages/utils/coremark
rm -rf feeds/packages/lang/node/node
#rm -rf feeds/packages/lang/golang
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

# 4. 更新 golang 1.26 版本
#git clone --depth=1 -b 26.x https://github.com/sbwml/packages_lang_golang feeds/packages/lang/golang

# 5. 主题与常规插件
# 添加dockerman主题
git clone https://github.com/sbwml/luci-app-dockerman feeds/luci/applications/luci-app-dockerman
sed -i 's/"admin/"admin\/services/g' feeds/luci/applications/luci-app-dockerman/root/usr/share/luci/menu.d/luci-app-dockerman.json
# 添加Lucky
#git clone --depth=1 -b main https://github.com/gdy666/luci-app-lucky package/lucky
# 添加系统高级设置
#git clone --depth=1 -b main https://github.com/free-diy/luci-app-advancedplus package/luci-app-advancedplus
# 添加clashoo
#git clone --depth=1 -b main https://github.com/kenzok8/openwrt-clashoo package/openwrt-clashoo
# 添加QiuSimons大鹅
#git clone --depth=1 -b kix https://github.com/QiuSimons/luci-app-dae package/openwrt-dae
git clone --depth=1 -b master https://github.com/QiuSimons/luci-app-honk package/openwrt-honk
git clone https://github.com/QiuSimons/vmlinux-btf package/vmlinux-btf
# 添加homeproxy
#git_sparse_clone v5 https://github.com/sbwml/openwrt_helloworld sing-box luci-app-homeproxy
sed -i "s/ImmortalWrt/OpenWrt/g" feeds/luci/applications/luci-app-homeproxy/po/zh_Hans/homeproxy.po
sed -i "s/ImmortalWrt proxy/OpenWrt proxy/g" feeds/luci/applications/luci-app-homeproxy/htdocs/luci-static/resources/view/homeproxy/{client.js,server.js}
# 添加Passwall 及其依赖
git_sparse_clone main https://github.com/Openwrt-Passwall/openwrt-passwall-packages v2ray-geodata sing-box xray-core
#git clone --depth=1 -b main https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/passwall-packages
#git clone --depth=1 -b main https://github.com/Openwrt-Passwall/openwrt-passwall package/passwall-luci
#git clone --depth=1 -b main https://github.com/Openwrt-Passwall/openwrt-passwall2 package/passwall12-luci
# 添加ssrplus
#git clone --depth=1 -b dev https://github.com/fw876/helloworld.git package/helloworld
# 添加中文版netdata
#git clone --depth=1 -b master https://github.com/sirpdboy/luci-app-netdata package/luci-app-netdata
# 添加应用管理
#git clone --depth=1 -b master https://github.com/destan19/OpenAppFilter package/OpenAppFilter
# 添加momo
#git clone --depth=1 -b main https://github.com/nikkinikki-org/OpenWrt-momo package/OpenWrt-momo
# 添加壁虎合集
#git clone --depth=1 -b main https://github.com/free-diy/all-proxy package/all-proxy
# 添加nikki
#git clone --depth=1 -b main https://github.com/YiXuanZX/OpenWrt-nikki package/OpenWrt-nikki
#git_sparse_clone main https://github.com/nikkinikki-org/OpenWrt-nikki luci-app-nikki mihomo-meta nikki
# 添加openclash
#git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash
# 添加partexp
git clone --depth=1 -b main https://github.com/sirpdboy/luci-app-partexp package/partexp
# 预编译 node
git clone --depth=1 -b packages-25.12 https://github.com/sbwml/feeds_packages_lang_node-prebuilt feeds/packages/lang/node/node
# 添加taskplan定时设置插件
#git_sparse_clone main https://github.com/sirpdboy/luci-app-taskplan luci-app-taskplan
# 添加设备关机功能
#git_sparse_clone master https://github.com/sirpdboy/luci-app-poweroffdevice luci-app-poweroffdevice
# 添加istore
#git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
#git_sparse_clone main https://github.com/linkease/istore luci
# 特别注意：iStore 的目录在仓库里叫 luci，移动到 package 后我们给它改个名防止冲突
#[ -d package/luci ] && mv package/luci package/luci-app-istore

# 替换autocore coremark default-settings
git clone --depth=1 -b openwrt-25.12 https://github.com/sbwml/autocore-arm package/autocore
git clone --depth=1 -b openwrt-25.12 https://github.com/sbwml/default-settings package/default-settings
git_sparse_clone master https://github.com/8688Add/openwrt_pkgs coremark

# 定义zzz-default-settings路径
ZZZ_FILE=$(find package/ feeds/ -type f -name "zzz-default-settings" 2>/dev/null | head -n 1)

if [ -n "$ZZZ_FILE" ]; then
    echo "发现 zzz-default-settings 路径: $ZZZ_FILE"
    
    sed -i '/disable coremark/d' "$ZZZ_FILE"
    sed -i '/sed -i.*coremark.*crontabs/d' "$ZZZ_FILE"
    sed -i '/crontab \/etc\/crontabs\/root/d' "$ZZZ_FILE"
    sed -i '/coremark/,/crontabs\/root/d' "$ZZZ_FILE"

    echo "=== 已成功从 zzz-default-settings 中移除 Coremark 相关逻辑 ==="
else
   echo "⚠️ 未找到 zzz-default-settings 文件，请检查源码目录结构"
fi

# 添加 rtp2httpd
#git_sparse_clone https://github.com/stackia/rtp2httpd/tree/main/openwrt-support/luci-app-rtp2httpd
#git_sparse_clone https://github.com/stackia/rtp2httpd/tree/main/openwrt-support/rtp2httpd

# 6. 修复与优化编译环境
# 禁用 Rust 的 LLVM 编译，节省 10GB+ 空间和大量时间
#if [ -f feeds/packages/lang/rust/Makefile ]; then
#    sed -i 's/ci-llvm=true/ci-llvm=false/g' feeds/packages/lang/rust/Makefile
#fi

#完全删除luci版本
#sed -i "s/+ ' \/ ' : '') + (luciversion ||/:/g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js

# ttyd
sed -i '3 a\\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

sed -i 's/解除网易云音乐播放限制/音乐解锁/g' feeds/luci/applications/luci-app-unblockneteasemusic/root/usr/share/luci/menu.d/luci-app-unblockneteasemusic.json
curl -fsSL https://raw.githubusercontent.com/0118Add/X86_64-Test/main/general/25_storage.js > ./feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/25_storage.js
#curl -fsSL https://raw.githubusercontent.com/immortalwrt/luci/master/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/29_ports.js > ./package/autocore/files/generic/29_ports.js

# 7. 其他
# 专门针对 advancedplus 的流氓逻辑进行清洗
#if [ -f package/luci-app-advancedplus/root/etc/init.d/advancedplus ]; then
#    sed -i '/zsh/d' package/luci-app-advancedplus/root/etc/init.d/advancedplus
#fi

# 8. 删除多余的插件
#rm -rf package/all-proxy/mihomo
#rm -rf package/helloworld/mihomo
