# 编译配置说明

本目录包含编译配置文件，用于自定义 Gemtek XR1710G 固件。

---

## 文件清单

| 文件 | 说明 | 执行时机 |
|------|------|---------|
| `plugins.conf` | LuCI 插件选择配置 | 编辑后生效 |
| `diy-part1.sh` | 编译前自定义脚本 Part 1 | `feeds install` 之后 |
| `diy-part2.sh` | 编译前自定义脚本 Part 2 | `make menuconfig` 之后 |

---

## ⚡ Workflow 动态配置

GitHub Actions 触发编译时，以下配置由 workflow **自动覆盖**：

| 配置项 | 来源 | 说明 |
|--------|------|------|
| `UPSTREAM` | workflow 选择 | `immortalwrt` 或 `openwrt` |
| `hostname` | workflow 选择 | 根据版本自动设置 (ImmortalWrt-XR1710G / OpenWrt-XR1710G) |
| `LAN IP` | workflow 输入 | 用户自定义，默认 `192.168.100.1` |
| 固件大小 | menuconfig | **自动计算**，无需手动设置 |

### 关于固件大小

🔴 **重要：** `CONFIG_TARGET_ROOTFS_SIZE` 仅适用于 **x86 架构 ext4 镜像**，对 NAND 设备无效。

XR1710G 使用 **SPI-NAND Flash (4GB)**：

| 分区 | 大小 | 说明 |
|------|------|------|
| bootloader | ~1MB | 引导程序 |
| uboot | ~2MB | U-Boot |
| firmware (kernel + rootfs) | ~3500MB | 系统分区 |
| overlay (可用) | ~3.5GB | 用户数据 |

**固件大小由 `make menuconfig` 根据设备配置自动计算**，无需手动指定。

### 覆盖原理

```
workflow inputs (upstream, lan_ip)
     ↓
Create Default Config 步骤
     ↓
读取 docs/system-default → 替换 hostname
读取 docs/network-default → 替换 LAN IP
     ↓
Apply Plugin Configuration 步骤
     ↓
读取 plugins.conf → 移除旧值 → 追加动态值
     ↓
生成临时文件 → 注入到 .config
```

### 触发方式

在 Actions 页面选择：
1. `upstream`: immortalwrt / openwrt
2. `lan_ip`: 自定义 LAN IP 地址 (默认: 192.168.100.1)
3. 点击运行

---

## ⚠️ 本地编译注意

本地编译时，这些值**不会被自动覆盖**，需要在对应文件中手动设置：

- `docs/system-default` - 修改 `option hostname` 值
- `docs/network-default` - 修改 `option ipaddr` 值
- `config/plugins.conf` - 修改 `UPSTREAM` 值

---

## plugins.conf - 插件配置

编辑此文件启用/禁用插件，采用 `CONFIG_PACKAGE_xxx=y` 格式。

### 插件分类

```bash
# --- 基础服务 ---
CONFIG_PACKAGE_luci-app-uhttpd=y    # Web服务器
CONFIG_PACKAGE_luci-app-ucode=y     # UCode 区间

# --- 广告拦截 ---
CONFIG_PACKAGE_luci-app-adguardhome=y    # AdGuard Home (推荐)

# --- 代理插件 (三选一或组合) ---
CONFIG_PACKAGE_luci-app-openclash=y     # OpenClash (推荐)
# CONFIG_PACKAGE_luci-app-passwall=y    # PassWall
# CONFIG_PACKAGE_luci-app-dae=y         # dae

# --- 下载工具 ---
# CONFIG_PACKAGE_luci-app-qbittorrent=y     # qBittorrent
# CONFIG_PACKAGE_luci-app-aria2=y          # Aria2

# --- 管理工具 ---
CONFIG_PACKAGE_luci-app-ttyd=y           # Web终端
CONFIG_PACKAGE_luci-app-diskman=y        # 磁盘管理
CONFIG_PACKAGE_luci-app-filebrowser=y    # 文件管理

# --- 系统工具 ---
CONFIG_PACKAGE_luci-app-autoreboot=y     # 定时重启
CONFIG_PACKAGE_luci-app-firewall=y       # 防火墙
CONFIG_PACKAGE_luci-app-nlbwmon=y        # 流量监控

# --- VPN ---
CONFIG_PACKAGE_luci-app-wireguard=y      # WireGuard VPN
```

---

## diy-part1.sh - 编译前配置 (Part 1)

**执行时机：** `./scripts/feeds install -a` 之后、`make` 之前

### 配置内容

```bash
# 网络功能
CONFIG_PACKAGE_luci-proto-ipv6=y       # IPv6 支持
CONFIG_PACKAGE_kmod-tcp-bbr=y          # BBR 拥塞控制
CONFIG_PACKAGE_luci-app-qos=y          # QoS 流量控制

# 流量卸载优化
CONFIG_PACKAGE_kmod-nf-flow=y          # 连接跟踪加速
CONFIG_PACKAGE_kmod-ipt-offload=y      # iptables offload
CONFIG_PACKAGE_kmod-nft-offload=y      # nftables offload

# NPU 硬件加速
CONFIG_PACKAGE_kmod-airoha-npu=y       # Airoha NPU 驱动

# WiFi 7 (MT7996) + MLO
CONFIG_PACKAGE_kmod-mt7996e=y           # WiFi 7 驱动
CONFIG_PACKAGE_kmod-mt7921e=y           # WiFi 6 驱动
CONFIG_PACKAGE_wpad-openssl=y           # WPA3 支持

# 10G 万兆网口
CONFIG_PACKAGE_kmod-phy-airoha=y       # Airoha PHY 驱动
CONFIG_PACKAGE_kmod-gsw-airoha=y       # Airoha 交换机驱动

# DSCP QoS
CONFIG_PACKAGE_kmod-ipt-dscp=y         # DSCP 标记

# 系统优化
CONFIG_PACKAGE_luci-app-openssh=y      # OpenSSH
CONFIG_TIME_ZONE="CST-8"               # 时区
```

### 配置说明

| 类别 | 功能 | 说明 |
|------|------|------|
| 网络 | IPv6, BBR, QoS | 基础网络功能 |
| 加速 | Flow-offload, NPU | 硬件加速 |
| 无线 | WiFi 7 + MLO | 三频 2.4G/5G/6G |
| 以太网 | 10G 万兆 | Airoha 以太网驱动 |
| QoS | DSCP offload | 流量优先级 |
| 系统 | OpenSSH, 时区 | 基础配置 |

---

## diy-part2.sh - 编译前配置 (Part 2)

**执行时机：** `make menuconfig` 之后、`make` 之前

### 配置内容

```bash
# 风扇/温度监控 (NCT7802 传感器)
CONFIG_PACKAGE_kmod-nct7802=y          # XR1710G 主板传感器

# WiFi 7 工具
CONFIG_PACKAGE_kmod-mt7996e=y           # WiFi 7 驱动
CONFIG_PACKAGE_kmod-mt7921e=y           # WiFi 6 驱动
CONFIG_PACKAGE_iw=y                     # 无线配置工具
CONFIG_PACKAGE_iwinfo=y                 # 无线信息工具

# 以太网工具
CONFIG_PACKAGE_kmod-airoha-enet-phy=y   # Airoha PHY
CONFIG_PACKAGE_kmod-phylib=y            # PHY 库
CONFIG_PACKAGE_kmod-phylink=y           # PHY 链路

# QoS/nftables
CONFIG_PACKAGE_nft-qos=y                # nftables QoS
CONFIG_PACKAGE_luci-app-nft-qos=y       # LuCI nftables QoS

# 文件系统
CONFIG_PACKAGE_block-mount=y            # 自动挂载
CONFIG_PACKAGE_kmod-fs-ext4=y           # ext4 支持
CONFIG_PACKAGE_kmod-fs-vfat=y           # FAT32 支持
CONFIG_PACKAGE_kmod-fs-ntfs=y           # NTFS 支持
CONFIG_PACKAGE_kmod-fs-exfat=y          # exFAT 支持

# NAND/SPI-NAND
CONFIG_PACKAGE_kmod-mtd=y               # MTD 子系统
CONFIG_PACKAGE_kmod-mtd-rw=y            # MTD 读写
CONFIG_PACKAGE_mtd-utils=y              # MTD 工具

# 网络监控
CONFIG_PACKAGE_luci-app-nlbwmon=y       # 流量监控
```

### 配置说明

| 类别 | 功能 | 说明 |
|------|------|------|
| 风扇控制 | NCT7802 | 温度监控 + 自动调速 |
| 无线 | MT7996/MT7921 | WiFi 7 驱动和工具 |
| 以太网 | Airoha PHY | 万兆网口支持 |
| QoS | nftables | 流量控制 |
| 存储 | 多文件系统 | 磁盘挂载支持 |
| NAND | MTD | SPI-NAND 闪存支持 |

---

## 网络配置 (docs/network-default)

自定义 LAN IP 地址，默认 `192.168.100.1`：

```bash
config interface 'lan'
    option proto 'static'
    option ipaddr '__LAN_IP__'      # 替换为自定义 IP
    option netmask '255.255.255.0'
```

---

## 执行顺序

```
┌─────────────────────────────────────────────────────────┐
│ 1. ./scripts/feeds update -a                           │
│ 2. ./scripts/feeds install -a                          │
│            ↓                                            │
│ 3. [运行 diy-part1.sh] ←── 第一阶段自定义配置           │
│            ↓                                            │
│ 4. make defconfig / make menuconfig                    │
│            ↓                                            │
│ 5. [运行 diy-part2.sh] ←── 第二阶段自定义配置           │
│            ↓                                            │
│ 6. make -j$(nproc)                                     │
└─────────────────────────────────────────────────────────┘
```

---

## 设备配置 (menuconfig)

在 `make menuconfig` 中选择：

```
Target System: Airoha ARM64
Subtarget: AN7581
Target Profile: Gemtek XR1710G
固件格式: sysupgrade.itb (squashfs)
```

---

## 固件信息

| 项目 | 说明 |
|------|------|
| 设备 | Gemtek XR1710G / W1700K |
| SoC | Airoha AN7581 (ARM64) |
| 内存 | 2GB DDR4 |
| 闪存 | 4GB SPI-NAND |
| WiFi | MT7996 WiFi 7 (2.4G/5G/6G) |
| 默认IP | 192.168.100.1 (可自定义) |
| 用户名 | root |
| 密码 | password |

---

## 刷入方式

### 方式一：U-Boot Web 刷入 (推荐)

1. **设备断电**
2. **按住 Reset 按钮**，同时接通电源
3. **等待 5 秒**，松开 Reset 按钮
4. 访问 `192.168.1.1` 进入恢复模式
5. 上传 `*-sysupgrade.itb` 文件

### 方式二：TFTP 刷入

1. 设置电脑 IP: `192.168.1.2/24`
2. 将固件命名为 `xr1710g-firmware.itb`
3. 设置 TFTP 服务器
4. 通过 U-Boot 命令刷入

### 方式三：SSH 刷入 (已有系统)

```bash
# 备份配置
sysupgrade -b /tmp/backup.tar.gz

# 上传固件并刷入 (使用自定义 IP)
scp openwrt-*-sysupgrade.itb root@192.168.100.1:/tmp/
ssh root@192.168.100.1
sysupgrade -n /tmp/openwrt-*-sysupgrade.itb
```

---

## 自定义插件开发

参考: [添加自定义插件说明](../../README.md#添加自定义插件)