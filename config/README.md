# 编译配置说明

本目录包含编译 XR1710G 固件所需的所有配置文件。修改配置后重新运行 Build Firmware 即可生效。

---

## 文件总览

| 文件 | 用途 |
|------|------|
| `plugins.conf` | LuCI 插件启停控制 |
| `diy-part1.sh` | 网络/无线/系统功能配置脚本（feeds 安装后执行） |
| `diy-part2.sh` | 内核模块/驱动/存储配置脚本（menuconfig 后执行） |
| `*-xr1710g.seed` | 设备配置种子，定义目标架构和基础包（三个上游通用） |

---

## plugins.conf — LuCI 插件配置

**作用：** 控制编译进固件的 LuCI Web 界面插件。修改后重新编译即可生效。

**工作原理：** Build Firmware 时，workflow 将此文件的 `CONFIG_PACKAGE_luci-app-xxx=y` 行追加到 `.config`，由 OpenWrt Kconfig 处理生成最终固件。

**格式说明：**

```
CONFIG_PACKAGE_luci-app-xxx=y    # 启用此插件（去掉 #）
# CONFIG_PACKAGE_luci-app-xxx=y  # 禁用此插件（保留 #）
```

**内置插件（默认启用，无需修改）：**

| 插件 | 说明 |
|------|------|
| luci-app-uhttpd | Web 服务器（必需） |
| luci-app-ucode | UCode 区间（必需） |
| luci-app-firewall | 防火墙（必需） |
| luci-app-openclash | OpenClash 代理（默认启用） |
| luci-app-ttyd | Web 终端 |
| luci-app-autoreboot | 定时重启 |

**按需启用的插件（去掉 # 生效）：**

| 插件 | 说明 | 编译时间 |
|------|------|---------|
| luci-app-passwall | PassWall 代理 | 较长 |
| luci-app-adguardhome | AdGuard Home 广告拦截 | 较长 |
| luci-app-qbittorrent | qBittorrent 下载 | 较长 |
| luci-app-aria2 | Aria2 下载 | 中等 |
| luci-app-diskman | 磁盘管理 | 短 |
| luci-app-filebrowser | 文件管理 | 短 |
| luci-app-wireguard | WireGuard VPN | 短 |
| luci-app-eqos | QoS 流控 | 短 |

**修改示例：** 启用 AdGuard Home 和 PassWall

```bash
# 修改 config/plugins.conf，将：
# CONFIG_PACKAGE_luci-app-adguardhome=y   # 去掉 # 前缀
# CONFIG_PACKAGE_luci-app-passwall=y      # 去掉 # 前缀
```

> **注意：** plugins.conf 中的 bash 注释（`# 描述文字`）不会影响编译，仅用于说明。

---

## diy-part1.sh — 前置配置脚本

**作用：** 在 `feeds install` 之后、`make` 之前运行，配置网络协议、无线驱动、硬件加速等核心功能。

**执行时机：**

```
1. ./scripts/feeds update -a
2. ./scripts/feeds install -a
          ↓
3. [diy-part1.sh]  ← 启用网络/无线/系统功能
          ↓
4. make defconfig / make menuconfig
          ↓
5. [diy-part2.sh]  ← 启用内核模块/驱动
          ↓
6. make -j$(nproc)
```

**各配置项说明：**

| 配置 | 说明 | 是否可修改 |
|------|------|-----------|
| `luci-proto-ipv6` | IPv6 协议支持 | 如不需要可注释 `sed` 行 |
| `kmod-tcp-bbr` / `kmod-tcp-bbr2` | BBR 拥塞控制，提升网络吞吐 | 如不需要可注释整行 |
| `luci-app-qos` | LuCI QoS 流量控制 | 如不需可注释 |
| `kmod-nf-flow` / `kmod-ipt-offload` | 连接跟踪和 iptables 卸载加速 | 建议保留，提升 NAT 性能 |
| `kmod-nft-offload` | nftables 硬件卸载 | 建议保留 |
| `kmod-airoha-npu` | Airoha AN7581 NPU 网络处理单元驱动 | 建议保留，XR1710G 专用 |
| `kmod-mt7996e` | MT7996 WiFi 7 驱动（6GHz + 5GHz） | XR1710G WiFi 驱动，勿删 |
| `kmod-mt7921e` | MT7921 WiFi 6 驱动（2.4GHz） | XR1710G WiFi 驱动，勿删 |
| `wpad-openssl` | WPA3 / 802.11k/v/r 支持 | 建议保留 |
| `kmod-phy-airoha` / `kmod-gsw-airoha` | Airoha 万兆 PHY + 交换机驱动 | 建议保留 |
| `kmod-act-sample` / `iptables-mod-dscp` | DSCP 服务质量标记 | 如不需可注释 |
| `luci-app-openssh` | OpenSSH | 建议保留 |
| `TIME_ZONE="CST-8"` | 中国时区 | 可改为其他时区 |

**修改示例：** 禁用 IPv6 支持

```bash
# 注释掉 diy-part1.sh 中的这行：
# sed -i 's/# CONFIG_PACKAGE_luci-proto-ipv6 is not set/CONFIG_PACKAGE_luci-proto-ipv6=y/g' .config
```

---

## diy-part2.sh — 后置配置脚本

**作用：** 在 `make menuconfig` 之后、`make` 之前运行，配置内核模块、文件系统、存储驱动等硬件相关功能。

**各配置项说明：**

| 配置 | 说明 | 是否可修改 |
|------|------|-----------|
| `kmod-nct7802` | NCT7802 风扇/温度传感器驱动 | XR1710G 主板传感器，建议保留 |
| `kmod-mt7996e` / `kmod-mt7921e` | WiFi 驱动 | 建议保留 |
| `iw` / `iwinfo` / `wireless-tools` | 无线配置工具 | 建议保留，用于 iwconfig 等 |
| `kmod-airoha-enet-phy` / `kmod-phylib` / `kmod-phylink` | PHY 网络接口驱动 | 建议保留 |
| `nft-qos` / `luci-app-nft-qos` | nftables 流量控制 | 如不需可注释 |
| `block-mount` / `kmod-fs-ext4/vfat/ntfs/exfat` | 文件系统支持（ext4/FAT/NTFS/exFAT） | 按需保留，减少不需要的文件系统可缩短编译时间 |
| `kmod-mtd` / `kmod-mtd-rw` / `mtd-utils` | SPI-NAND MTD 闪存支持 | XR1710G 必需，勿删 |
| `luci-app-nlbwmon` | 流量监控 | 如不需可注释 |
| `luci-app-ledtrig-default-trigger` | LED 指示灯触发 | 如不需可注释 |

**修改示例：** 移除 NTFS 和 exFAT 支持以减少编译时间

```bash
# 在 diy-part2.sh 中注释：
# grep -q "CONFIG_PACKAGE_kmod-fs-ntfs=y" .config || echo "CONFIG_PACKAGE_kmod-fs-ntfs=y" >> .config
# grep -q "CONFIG_PACKAGE_kmod-fs-exfat=y" .config || echo "CONFIG_PACKAGE_kmod-fs-exfat=y" >> .config
```

---

## *-xr1710g.seed — 设备配置种子

**作用：** 定义目标设备为 Airoha AN7581 / XR1710G 的完整 `.config` 基线，包含目标架构、内核选项和基础包。

**三个文件的区别：**

| 文件 | 对应上游 | 使用场景 |
|------|---------|---------|
| `immortalwrt-xr1710g.seed` | ImmortalWrt | 编译 ImmortalWrt 版本时使用 |
| `openwrt-xr1710g.seed` | OpenWrt | 编译 OpenWrt 版本时使用 |
| `istoreos-xr1710g.seed` | iStoreOS | 编译 iStoreOS 版本时使用 |

> **当前状态：** 三个 seed 文件内容相同（同一份设备配置），保留三个文件是为将来上游配置出现差异时预留扩展空间。无需分别修改。

**文件内容结构：**

```
# 自动生成文件，请勿手动编辑
CONFIG_TARGET_airoha=y                  ← 目标架构为 Airoha
CONFIG_TARGET_ROOTFS_SQUASHFS=y         ← squashfs 根文件系统
CONFIG_PACKAGE_luci-app-xxx=y           ← 基础包选择（约2000行）
CONFIG_KERNEL_xxx=y                    ← 内核配置
```

**如何修改 seed 文件：**

不建议直接编辑。正确方式：
1. 运行一次完整的 Build Firmware
2. 下载 artifact 中的 `config.seed` 文件
3. 将其重命名为对应的 `{upstream}-xr1710g.seed` 并上传替换

> Seed 文件本质上是完整的 OpenWrt `.config`，由 `make defconfig` + DIY 脚本生成，直接手动修改容易引入格式错误。

---

## 本地编译配置流程

本地编译时，这些文件不会被 workflow 自动覆盖，需确保值正确：

| 文件 | 本地需检查的值 |
|------|--------------|
| `docs/system-default` | hostname（默认 ImmortalWrt-XR1710G 等） |
| `docs/network-default` | LAN IP（默认 192.168.100.1） |
| `config/plugins.conf` | 插件选择 |
| `config/diy-part1.sh` | 网络/无线功能 |
| `config/diy-part2.sh` | 驱动/存储功能 |

### 本地编译完整示例

```bash
# 1. 准备源码（iStoreOS 为例）
./scripts/get-source.sh istoreos
cd istoreos

# 2. 运行业务配置（网络、无线、系统）
bash ../config/diy-part1.sh

# 3. 选择设备
make menuconfig
# Target System → Airoha ARM64
# Subtarget → AN7581
# Target Profile → Gemtek XR1710G

# 4. 运行硬件配置（内核模块、驱动、存储）
bash ../config/diy-part2.sh

# 5. 开始编译
make -j$(nproc)
```

---

## 常见问题

**Q: 启用了太多插件，编译内存不足怎么办？**
A: 减少 `plugins.conf` 中的插件数量，或在 seed 文件中关闭不需要的基础包。

**Q: 编译失败，报 `CONFIG_TARGET_ROOTFS_SIZE` 错误？**
A: 删除注释或手动设置的 `CONFIG_TARGET_ROOTFS_SIZE`。XR1710G 是 NAND 设备，固件大小由内核自动计算，无需手动指定。

**Q: WiFi 搜不到信号？**
A: 检查 `diy-part1.sh` 中 `kmod-mt7996e` 和 `kmod-mt7921e` 是否被注释，`wpad-openssl` 是否启用。

**Q: 想添加 plugins.conf 中没有的插件？**
A: 使用 Sync Plugins workflow 添加第三方 `luci-app-*` 到 `apps/custom/`，然后在 `plugins.conf` 中添加对应的 `CONFIG_PACKAGE_xxx=y` 行。