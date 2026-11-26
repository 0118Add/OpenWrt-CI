##dae/honk
openwrt_dir="${OPENWRT_DIR:-.}"
feeds_dir="${FEEDS_DIR:-${openwrt_dir}/feeds}"
pkg_dir="${PKG_DIR:-${openwrt_dir}/package}"
dae_pkg_dir="${DAE_PKG_DIR:-${pkg_dir}/dae-packages}"
dae_src_dir="${DAE_SRC_DIR:-${dae_pkg_dir}/dae/src}"
honk_src_dir="${HONK_SRC_DIR:-${dae_pkg_dir}/honk/src}"

rm -rf \
  "${feeds_dir}/luci/applications/luci-app-dae" \
  "${feeds_dir}/luci/applications/luci-app-honk" \
  "${feeds_dir}/packages/net/dae" \
  "${feeds_dir}/packages/net/honk"

if [ -d "$dae_pkg_dir" ]; then
  git -C "$dae_pkg_dir" pull || true
  [ -d "$dae_src_dir" ] && { git -C "$dae_src_dir" pull || true; }
  [ -d "$honk_src_dir" ] && { git -C "$honk_src_dir" pull || true; }
else
  git clone https://github.com/daeuniverse/openwrt-packages "$dae_pkg_dir"
  git clone --recurse-submodules https://github.com/daeuniverse/dae "$dae_src_dir"
  git clone --recurse-submodules https://github.com/daeuniverse/honk "$honk_src_dir"
fi

# Prepare host Rust from the checked-out honk source requirements.
# Isolate strict error handling and upstream pins from the rest of this script.
(
  set -euo pipefail

  [ -d "$honk_src_dir" ] || {
    echo "honk source directory not found: $honk_src_dir" >&2
    exit 1
  }
  src="$(realpath "$honk_src_dir")"

  # 自动定位 build.sh 与 pins.env，兼容目录调整
  honk_build_sh="${HONK_BUILD_SH:-}"
  if [ -z "$honk_build_sh" ]; then
    for candidate in \
      "${dae_pkg_dir}/honk/build.sh" \
      "${src}/openwrt/build.sh" \
      "${src}/build.sh"
    do
      if [ -f "$candidate" ]; then
        honk_build_sh="$candidate"
        break
      fi
    done
  fi
  [ -n "$honk_build_sh" ] && [ -f "$honk_build_sh" ] || {
    echo "Cannot find honk build.sh" >&2
    exit 1
  }

  pins_file="${HONK_PINS_ENV:-}"
  if [ -z "$pins_file" ]; then
    for candidate in \
      "${src}/.github/ci/pins.env" \
      "${dae_pkg_dir}/honk/.github/ci/pins.env"
    do
      if [ -f "$candidate" ]; then
        pins_file="$candidate"
        break
      fi
    done
  fi
  [ -n "$pins_file" ] && [ -f "$pins_file" ] || {
    echo "Cannot find honk pins.env" >&2
    exit 1
  }

  # The pinned bpf-linker checksum describes the x86_64 Linux host asset.
  [[ "$(uname -s)" == Linux && "$(uname -m)" == x86_64 ]] || {
    echo 'This script requires an x86_64 Linux build host' >&2; exit 1;
  }

  # Install every Rust userspace target declared by the OpenWrt honk recipe.
  # Several OpenWrt CPU variants can share the same Rust target.
  target_text="$(python3 - "$honk_build_sh" <<'PY_TARGETS'
import pathlib, re, sys
text = pathlib.Path(sys.argv[1]).read_text()
section = re.search(r'case[^\n]*HONK_ARCH_PACKAGES[^\n]*\bin\s*\n(.*?)\besac\b', text, re.S)
if section is None:
    sys.exit("Cannot locate the honk architecture mapping in build.sh")
targets = sorted(set(re.findall(r"\btarget\s*=\s*[\"']?([A-Za-z0-9_]+(?:-[A-Za-z0-9_.]+){2,})", section.group(1))))
if not targets:
    sys.exit("No literal Rust targets found; review the upstream honk architecture mapping")
print("\n".join(targets))
PY_TARGETS
  )"
  mapfile -t targets <<< "$target_text"
  printf 'Preparing honk Rust target: %s\n' "${targets[@]}"

  # Must run as the same ordinary user that runs OpenWrt make.
  export CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
  export RUSTUP_HOME="${RUSTUP_HOME:-$HOME/.rustup}"
  linker_bin_dir="${BPF_LINKER_BIN_DIR:-$CARGO_HOME/bin}"
  export PATH="$CARGO_HOME/bin:$linker_bin_dir:$PATH"

  if ! command -v rustup >/dev/null 2>&1; then
    curl --retry 3 --retry-delay 2 --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain none --no-modify-path
  fi

  stable="$(python3 -c 'import sys,tomllib;print(tomllib.load(open(sys.argv[1],"rb"))["toolchain"]["channel"])' "$src/rust-toolchain.toml")"
  nightly="$(python3 -c 'import sys,tomllib;print(tomllib.load(open(sys.argv[1],"rb"))["toolchain"]["channel"])' "$src/crates/honk-ebpf/rust-toolchain.toml")"

  rustup toolchain install "$stable" --profile minimal --component rustfmt,clippy
  rustup target add --toolchain "$stable" "${targets[@]}"
  rustup toolchain install "$nightly" --profile minimal --component rust-src,llvm-tools

  # Same trusted pins file and same host binary as the upstream package workflow.
  source "$pins_file"
  archive="$(mktemp --suffix=.tar.zst)"
  curl -fLsS --retry 3 -o "$archive" \
    "https://github.com/aya-rs/bpf-linker/releases/download/v${BPF_LINKER_VERSION}/bpf-linker-x86_64-unknown-linux-musl.tar.zst"
  printf '%s  %s\n' "$BPF_LINKER_SHA256" "$archive" | sha256sum -c -
  mkdir -p "$linker_bin_dir"
  tar --zstd -xf "$archive" -C "$linker_bin_dir"
  rm -f "$archive"

  (cd "$src"; cargo --version; rustc --version; bpf-linker --version)
  rustup target list --installed --toolchain "$stable"

  # GitHub Actions starts a new shell for every step.
  if [[ -n "${GITHUB_ENV:-}" && -n "${GITHUB_PATH:-}" ]]; then
    printf 'CARGO_HOME=%s\nRUSTUP_HOME=%s\n' "$CARGO_HOME" "$RUSTUP_HOME" >> "$GITHUB_ENV"
    printf '%s\n' "$CARGO_HOME/bin" "$linker_bin_dir" | awk '!seen[$0]++' >> "$GITHUB_PATH"
  fi
)
honk_rust_status=$?

if [ "$honk_rust_status" -eq 0 ]; then
  _cargo_home="${CARGO_HOME:-$HOME/.cargo}"
  _rustup_home="${RUSTUP_HOME:-$HOME/.rustup}"
  _linker_bin_dir="${BPF_LINKER_BIN_DIR:-$_cargo_home/bin}"

  # 非 GitHub Actions 环境：先导出到当前主脚本进程，确保后续 make 立即可用
  if [ -z "${GITHUB_ENV:-}" ]; then
    export CARGO_HOME="$_cargo_home"
    export RUSTUP_HOME="$_rustup_home"
    [ -f "$_cargo_home/env" ] && . "$_cargo_home/env"
    export PATH="$_cargo_home/bin:$_linker_bin_dir:$PATH"

    # 若为交互式终端，额外持久化写入 ~/.bashrc，方便以后手动登录终端使用
    if [ -t 1 ] || [[ $- == *i* ]]; then
      _bashrc="${HOME}/.bashrc"
      for _line in \
        "export CARGO_HOME=\"$_cargo_home\"" \
        "export RUSTUP_HOME=\"$_rustup_home\"" \
        "export PATH=\"$_cargo_home/bin:$_linker_bin_dir:\$PATH\""
      do
        grep -qxF "$_line" "$_bashrc" 2>/dev/null || printf '%s\n' "$_line" >> "$_bashrc"
      done
      echo "Detected interactive local shell: persisted Rust/bpf-linker env to $_bashrc"
    else
      echo "Detected non-interactive local environment: exported Rust/bpf-linker env for current process only"
    fi
  fi

  unset _cargo_home _rustup_home _linker_bin_dir _bashrc _line
else
  echo "honk Rust environment preparation failed" >&2
  exit "$honk_rust_status"
fi
##End of dae/honk
