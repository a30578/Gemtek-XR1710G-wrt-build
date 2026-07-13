# Gemtek XR1710G 固件编译项目

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

## 插件管理

本项目提供完整的插件管理功能，支持通过 GitHub Actions 一键添加第三方插件。

### package/custom/ 目录说明

```
package/custom/                  # 自定义插件目录（编译时自动复制到源码）
├── small-package/               # 克隆的插件仓库
│   ├── luci-app-smartdns/       # smartdns 插件
│   ├── luci-app-unishare/       # unishare 插件
│   └── ...
└── another-repo/                # 其他插件仓库
    └── luci-app-xxx/
```

**作用：**
- 存放从第三方仓库克隆的插件集合
- 编译时 `scripts/get-source.sh` 会自动复制到 OpenWrt 源码 `package/` 目录
- 通过 `config/plugins.conf` 启用后会在编译时包含到固件中

### Sync Plugins Workflow

**路径：** `.github/workflows/sync-plugins.yml`

**功能：** 通过 GitHub Actions 管理 `package/custom/` 中的第三方插件

#### 可用操作

| 操作 | 说明 |
|------|------|
| `clone` | 从第三方 GitHub 仓库克隆插件到 `package/custom/` |
| `clear` | 清空 `package/custom/` 中的所有插件 |

#### 操作一：克隆插件仓库 (clone) ⭐推荐

从第三方仓库添加所有插件：

1. 进入仓库 → **Actions** → **Sync Plugins**
2. 点击 **Run workflow**（无需修改任何参数，直接运行即可）
3. 默认配置：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| repo_path | `kenzok8/small-package` | 插件仓库路径 |

4. 点击运行

**Workflow 自动完成：**
- ✅ 下载整个 GitHub 仓库到 `package/custom/small-package/`
- ✅ 列出仓库中所有可用的 `luci-app-*` 插件
- ✅ 自动提交并推送到 GitHub

**目录结构：**
```
package/custom/small-package/
├── luci-app-unishare/
├── luci-app-smartdns/
├── luci-app-xxx/
└── ...
```

#### 操作二：清空插件 (clear)

移除所有自定义插件：

1. 进入仓库 → **Actions** → **Sync Plugins**
2. 点击 **Run workflow**
3. `action` 选择 `clear`
4. 点击运行

**注意：** 清空前会先自动备份到 `package/custom.bak/`

#### 查看插件列表

直接到 GitHub 仓库查看 `package/custom/` 目录，或查看 Actions 运行日志中的插件列表输出。

### 常用插件仓库

| 插件集合 | 仓库路径 | 说明 |
|----------|----------|------|
| 小丸插件 | `kenzok8/small-package` | 常用插件集合 |
| OpenWrt 常用插件 | `kenzok8/openwrt-packages` | 更多插件 |

### 启用插件

克隆插件仓库后，需要在 `config/plugins.conf` 中启用要编译的插件：

```bash
# 在 plugins.conf 中添加（根据实际需要的插件启用）
CONFIG_PACKAGE_luci-app-smartdns=y
CONFIG_PACKAGE_luci-app-unishare=y
CONFIG_PACKAGE_luci-app-wolplus=y
```

然后触发 **Build Firmware** workflow 重新编译即可。

### 完整插件添加流程（以 small-package 为例）

```
1. GitHub Actions → Sync Plugins → Run workflow
   ↓
2. 直接点击运行（默认 repo_path: kenzok8/small-package）
   ↓
3. GitHub 自动下载整个仓库到 package/custom/small-package/
   ↓
4. 编辑 config/plugins.conf 添加启用的插件:
   CONFIG_PACKAGE_luci-app-smartdns=y
   CONFIG_PACKAGE_luci-app-unishare=y
   ↓
5. GitHub Actions → Build Firmware → 编译
   ↓
6. 下载固件，插件已包含在内
```

### 查看可用插件

运行 Sync Plugins workflow 后，在日志的 `Copy All Plugins to package/custom` 步骤可以看到所有可用的插件列表，格式如：

```
=== 可用插件列表 ===
- smartdns
- unishare
- wolplus
- ...
```

## 插件说明

编辑 `config/plugins.conf` 自定义插件组合：

```bash
# 格式: CONFIG_PACKAGE_xxx=y (启用) 或 # CONFIG_PACKAGE_xxx=y (禁用)

# 网络工具
CONFIG_PACKAGE_luci-app-eqos=y          # QoS流控
CONFIG_PACKAGE_luci-app-adguardhome=y   # 广告拦截

# 代理插件
CONFIG_PACKAGE_luci-app-openclash=y      # OpenClash
CONFIG_PACKAGE_luci-app-passwall=y       # PassWall

# 管理工具
CONFIG_PACKAGE_luci-app-ttyd=y           # Web终端
CONFIG_PACKAGE_luci-app-diskman=y        # 磁盘管理

# 自定义插件（从 package/custom/ 添加）
CONFIG_PACKAGE_luci-app-xiaowan=y        # 小丸插件
```

## 固件大小配置

🔴 **重要：** XR1710G 使用 **SPI-NAND Flash (4GB)**，固件分区由系统自动计算，无需手动设置。

| 分区 | 大小 | 说明 |
|------|------|------|
| bootloader | ~1MB | 引导程序 |
| uboot | ~2MB | U-Boot |
| 系统分区 | ~3500MB | kernel + rootfs |
| overlay (可用) | ~3.5GB | 用户数据/插件 |

> 💡 无需担心固件大小，安装插件时直接使用 overlay 分区空间。

## 默认配置

> 💡 编译时可自定义 LAN IP，未自定义时默认如下：

| 项目 | OpenWrt/ImmortalWrt | iStoreOS |
|------|---------------------|----------|
| 管理IP | 192.168.100.1 | 192.168.100.1 |
| 用户名 | root | root |
| 密码 | 无（首次登录设置） | password |
| WiFi密码 | 12345678 | 12345678 |
| WAN口 | 第1个网口 | 第1个网口 |
| LAN口 | 其余网口 | 其余网口 |

## 分支说明

- `main` - 基础编译框架（通用，支持 OpenWrt / ImmortalWrt / iStoreOS）

## 常见问题

**Q: 编译失败怎么办？**
A: 检查 Actions 日志，常见问题：内存不足（建议16GB+）、磁盘空间不足（建议200GB+）

**Q: 固件如何刷入？**
A: 使用 U-Boot Web 刷入页面，或通过 TFTP 刷入

**Q: 如何添加未在 feeds 中的第三方插件？**
A: 使用 Sync Plugins workflow 的 clone 功能，选择对应的仓库和插件名即可

## 脚本说明

### `/scripts/get-source.sh`

**用途：** 本地编译环境一键准备脚本

**功能：**
| 功能 | 说明 |
|------|------|
| 安装依赖 | 自动安装 Ubuntu/Debian 或 CentOS 编译依赖 |
| 克隆源码 | 克隆 OpenWrt/ImmortalWrt/iStoreOS 源码 (默认 openwrt-25.12) |
| 更新 feeds | 执行 `./scripts/feeds update -a` |
| 安装自定义插件 | 自动复制 `package/custom/` 到源码目录 |
| 链接 DIY 脚本 | 自动复制 `config/diy-part1.sh` 和 `diy-part2.sh` |

**用法：**
```bash
# 默认克隆 iStoreOS
./scripts/get-source.sh

# 指定上游版本
./scripts/get-source.sh openwrt           # OpenWrt
./scripts/get-source.sh immortalwrt       # ImmortalWrt
./scripts/get-source.sh istoreos          # iStoreOS

# 指定分支
./scripts/get-source.sh openwrt openwrt-25.12

# 同时克隆所有版本
./scripts/get-source.sh all
```

**输出目录：** `istoreos/` / `immortalwrt/` / `openwrt/`

## 参考仓库

- [naoki66/ImmortalWrt-for-Gemtek-XR1710G](https://github.com/naoki66/ImmortalWrt-for-Gemtek-XR1710G)
- [hx801217/iStoreOS-for-Gemtek-XR1710G](https://github.com/hx801217/iStoreOS-for-Gemtek-XR1710G)
- [lvcdy/openwrt_xr1710g](https://github.com/lvcdy/openwrt_xr1710g)

## 致谢

本项目参考了上述开源仓库的编译配置。
