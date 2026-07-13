# Gemtek XR1710G 固件编译项目

> **⚠️ 暂时不要选择 OpenWrt 和 iStoreOS 进行编译，目前仅推荐使用 ImmortalWrt。**

支持 **OpenWrt** / **ImmortalWrt** / **iStoreOS** 一键编译，可自由选择上游版本和插件组合。

## 设备支持

| 型号 | SoC | 架构 | 固件格式 |
|------|-----|------|----------|
| Gemtek XR1710G | Airoha AN7581 | ARM64 (airoha/an7581) | sysupgrade.itb |

**硬件规格：**
- CPU: ARM Cortex-A53 四核 @ 1.5GHz
- 内存: 2GB DDR4
- 闪存: 4GB SPI-NAND (固件分区自动计算)

## 编译版本

| 版本 | 分支 | 特点 | 选择参数 |
|------|------|------|---------|
| **iStoreOS** | openwrt-25.12 | 易用 Web 界面，预装丰富插件 | 选择 iStoreOS |
| **ImmortalWrt** | openwrt-25.12 | 预装丰富插件 (OpenClash/PassWall/dae/AdGuard Home) | 选择 ImmortalWrt |
| **OpenWrt** | openwrt-25.12 | 最小化定制，更接近上游 | 选择 OpenWrt |

## 使用方法

### 方法一：Fork后手动触发 (推荐)

1. Fork 本仓库
2. 点击 **Actions** → 选择 **Build Firmware** → **Run workflow**
3. 选择配置：
   - `upstream`: istoreos / immortalwrt / openwrt
   - `lan_ip`: 自定义 LAN IP (默认: 192.168.100.1)
   - `wifi_password`: 自定义 WiFi 密码 (默认: 12345678)
4. 点击运行，等待编译完成

### 方法二：本地编译

**方式一：使用自动化脚本（推荐）**

```bash
# 克隆仓库
git clone https://github.com/Arthur97172/Gemtek-XR1710G-wrt-build.git
cd Gemtek-XR1710G-wrt-build

# 一键准备编译环境（克隆源码 + 安装依赖 + 配置 feeds）
./scripts/get-source.sh              # 默认克隆 iStoreOS
./scripts/get-source.sh immortalwrt  # 克隆 ImmortalWrt
./scripts/get-source.sh openwrt      # 克隆 OpenWrt
./scripts/get-source.sh all          # 同时克隆三个版本

# 配置并编译 (以 iStoreOS 为例)
cd istoreos
source diy/diy-part1.sh              # 运行业务配置
make menuconfig                      # 选择设备
source ../diy/diy-part2.sh           # 运行硬件配置
make -j$(nproc)                      # 开始编译
```

**方式二：手动配置**

```bash
# 克隆仓库
git clone https://github.com/Arthur97172/Gemtek-XR1710G-wrt-build.git
cd Gemtek-XR1710G-wrt-build

# 选择要编译的上游版本 (三选一):

# ========== iStoreOS ==========
git clone --depth=1 --branch=openwrt-25.12 https://github.com/istoreos/istoreos.git istoreos
cd istoreos
./scripts/feeds update -a && ./scripts/feeds install -a

# ========== ImmortalWrt ==========
git clone --depth=1 --branch=openwrt-25.12 https://github.com/immortalwrt/immortalwrt.git immortalwrt
cd immortalwrt
./scripts/feeds update -a && ./scripts/feeds install -a

# ========== OpenWrt ==========
git clone --depth=1 --branch=openwrt-25.12 https://github.com/openwrt/openwrt.git openwrt
cd openwrt
./scripts/feeds update -a && ./scripts/feeds install -a

# 配置 (通用)
make menuconfig
# 选择: Target System → Airoha ARM64, Subtarget → AN7581, Target Profile → Gemtek XR1710G

# 编译
make -j$(nproc)
```

## Actions 工作流

本仓库有三个 GitHub Actions 工作流：

| 工作流 | 文件 | 用途 |
|--------|------|------|
| **Build Firmware** | `.github/workflows/build.yml` | 编译固件 |
| **Sync Target Files** | `.github/workflows/sync-target.yml` | 同步设备树、驱动、U-Boot |
| **Sync Custom Plugins** | `.github/workflows/sync-plugins.yml` | 管理第三方 LuCI 插件 |

---

### Sync Target Files

同步 XR1710G 设备专用的 **target 文件**（设备树、内核配置）和 **U-Boot 固件**，来自上游 [`lvcdy/openwrt_xr1710g`](https://github.com/lvcdy/openwrt_xr1710g)。

| 操作 | 说明 |
|------|------|
| `sync` | 从上游拉取最新 target/linux/airoha 和 package/boot/uboot-airoha，备份旧文件后替换 |
| `clear` | 删除本地 target 文件夹内容，提交清理记录 |

> `target/linux/airoha/` 和 `package/boot/uboot-airoha/` 属于设备专用定制，不参与上游合并，通过此 workflow 独立维护。

---

### Sync Custom Plugins

管理 `apps/custom/` 目录下的第三方 LuCI 插件集合，支持从预设或自定义仓库克隆。

| 操作 | 说明 |
|------|------|
| `clone` | 从上游仓库克隆完整插件集，覆盖 apps/custom/ 目录 |
| `clear` | 删除 apps/custom/ 中指定的仓库目录 |

**预设插件仓库：**

| 插件集合 | 仓库路径 |
|----------|----------|
| 小丸插件 | `kenzok8/small-package` |
| OpenWrt 常用插件 | `kenzok8/openwrt-packages` |
| HelloWorld | `fw876/helloworld` |
| OpenClash | `vernesong/OpenClash` |
| OP 插件包 | `kiddin9/op-packages` |
| 自定义 | 输入自定义 `owner/repo` 路径 |

**克隆插件后：** 编辑 `config/plugins.conf` 启用所需插件（`CONFIG_PACKAGE_luci-app-xxx=y`），再运行 Build Firmware 编译即可。

---

### Build Firmware

一键编译 XR1710G 固件，可自由选择上游版本。

#### 运行方式

1. 点击 **Actions** → 选择 **Build Firmware** → **Run workflow**
2. 配置参数（均可选填）：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| upstream | immortalwrt | 上游版本：istoreos / immortalwrt / openwrt |
| lan_ip | 192.168.100.1 | 路由 LAN 口 IP |
| wifi_password | 12345678 | WiFi 密码 |
| debug | false | 调试模式 |

3. 等待编译完成（约 4–10 小时），固件自动打包下载

#### 编译产物

编译完成后在 Actions 运行页面下载 artifact，包含：
- `*.itb` — 固件文件
- `config.seed` — 本次编译使用的完整配置

#### 本地编译

```bash
# 一键准备环境 + 克隆源码
./scripts/get-source.sh immortalwrt

# 进入源码目录编译
cd immortalwrt
make -j$(nproc)
```

---

## 插件管理

### apps/custom/ 目录说明

```
apps/custom/                      # 第三方插件目录（由 sync-plugins 工作流管理）
├── small-package/                # 克隆的插件仓库
│   ├── luci-app-smartdns/
│   ├── luci-app-unishare/
│   └── ...
└── another-repo/
    └── luci-app-xxx/
```

- 由 **Sync Custom Plugins** workflow 管理，编译时自动复制到 OpenWrt 源码的 `package/` 目录
- 编辑 `config/plugins.conf` 中的 `CONFIG_PACKAGE_luci-app-xxx=y` 启用插件

### 完整插件添加流程

```
1. Actions → Sync Custom Plugins → Run workflow（默认 kenzok8/small-package）
   ↓
2. 自动下载插件到 apps/custom/small-package/
   ↓
3. 编辑 config/plugins.conf 启用插件:
   CONFIG_PACKAGE_luci-app-smartdns=y
   CONFIG_PACKAGE_luci-app-unishare=y
   ↓
4. Actions → Build Firmware → 编译
   ↓
5. 下载固件，插件已包含在内
```

### config/plugins.conf 格式

```bash
# 启用插件（去掉 # 前缀）
CONFIG_PACKAGE_luci-app-openclash=y    # 代理
CONFIG_PACKAGE_luci-app-adguardhome=y  # 广告拦截
CONFIG_PACKAGE_luci-app-ttyd=y         # Web 终端

# 禁用插件（加 # 前缀）
# CONFIG_PACKAGE_luci-app-passwall=y
```

### 查看可用插件

运行 Sync Plugins workflow 后，在日志中可以看到所有可用的 `luci-app-*` 插件列表：

```
=== 可用插件列表 ===
- smartdns
- unishare
- wolplus
- ...
```

---

## 默认配置

| 项目 | OpenWrt / ImmortalWrt | iStoreOS |
|------|----------------------|----------|
| 管理 IP | 192.168.100.1 | 192.168.100.1 |
| 用户名 | root | root |
| 密码 | 无（首次登录设置） | password |
| WiFi 密码 | 12345678 | 12345678 |
| WAN 口 | 第 1 个网口 | 第 1 个网口 |
| LAN 口 | 其余网口 | 其余网口 |

## 常见问题

**Q: 编译失败怎么办？**
A: 检查 Actions 日志，常见问题：内存不足（建议 16GB+）、磁盘空间不足（建议 200GB+）

**Q: 固件如何刷入？**
A: 使用 U-Boot Web 刷入页面，或通过 TFTP 刷入

## 参考仓库

- [naoki66/ImmortalWrt-for-Gemtek-XR1710G](https://github.com/naoki66/ImmortalWrt-for-Gemtek-XR1710G)
- [hx801217/iStoreOS-for-Gemtek-XR1710G](https://github.com/hx801217/iStoreOS-for-Gemtek-XR1710G)
- [lvcdy/openwrt_xr1710g](https://github.com/lvcdy/openwrt_xr1710g)
