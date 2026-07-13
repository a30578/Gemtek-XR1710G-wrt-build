#!/bin/bash
# ========================================
# 编译前自定义脚本 Part 2
# 在 make menuconfig 之后、make 之前运行
# ========================================

echo "[Customize Part 2] 开始后置配置..."

# ========== 风扇/温度监控 (NCT7802 传感器) ==========

grep -q "CONFIG_PACKAGE_kmod-nct7802=y" .config || echo "CONFIG_PACKAGE_kmod-nct7802=y" >> .config

# ========== WiFi 7 (MT7996) 驱动 ==========

grep -q "CONFIG_PACKAGE_kmod-mt7996e=y" .config || echo "CONFIG_PACKAGE_kmod-mt7996e=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-mt7921e=y" .config || echo "CONFIG_PACKAGE_kmod-mt7921e=y" >> .config
grep -q "CONFIG_PACKAGE_iw=y" .config || echo "CONFIG_PACKAGE_iw=y" >> .config
grep -q "CONFIG_PACKAGE_iwinfo=y" .config || echo "CONFIG_PACKAGE_iwinfo=y" >> .config
grep -q "CONFIG_PACKAGE_wireless-tools=y" .config || echo "CONFIG_PACKAGE_wireless-tools=y" >> .config
grep -q "CONFIG_PACKAGE_hostapd-utils=y" .config || echo "CONFIG_PACKAGE_hostapd-utils=y" >> .config

# ========== 以太网/网络 ==========

grep -q "CONFIG_PACKAGE_kmod-airoha-enet-phy=y" .config || echo "CONFIG_PACKAGE_kmod-airoha-enet-phy=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-phylib=y" .config || echo "CONFIG_PACKAGE_kmod-phylib=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-phylink=y" .config || echo "CONFIG_PACKAGE_kmod-phylink=y" >> .config

# ========== QoS/nftables ==========

grep -q "CONFIG_PACKAGE_nft-qos=y" .config || echo "CONFIG_PACKAGE_nft-qos=y" >> .config
grep -q "CONFIG_PACKAGE_luci-app-nft-qos=y" .config || echo "CONFIG_PACKAGE_luci-app-nft-qos=y" >> .config

# ========== 文件系统 ==========

grep -q "CONFIG_PACKAGE_block-mount=y" .config || echo "CONFIG_PACKAGE_block-mount=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-fs-ext4=y" .config || echo "CONFIG_PACKAGE_kmod-fs-ext4=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-fs-vfat=y" .config || echo "CONFIG_PACKAGE_kmod-fs-vfat=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-fs-ntfs=y" .config || echo "CONFIG_PACKAGE_kmod-fs-ntfs=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-fs-exfat=y" .config || echo "CONFIG_PACKAGE_kmod-fs-exfat=y" >> .config

# ========== NAND/SPI-NAND 支持 ==========

grep -q "CONFIG_PACKAGE_kmod-mtd=y" .config || echo "CONFIG_PACKAGE_kmod-mtd=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-mtd-rw=y" .config || echo "CONFIG_PACKAGE_kmod-mtd-rw=y" >> .config
grep -q "CONFIG_PACKAGE_mtd-utils=y" .config || echo "CONFIG_PACKAGE_mtd-utils=y" >> .config

# ========== LED 指示灯 ==========

grep -q "CONFIG_PACKAGE_luci-app-ledtrig-default-trigger=y" .config || echo "CONFIG_PACKAGE_luci-app-ledtrig-default-trigger=y" >> .config

# ========== 网络监控 ==========

grep -q "CONFIG_PACKAGE_luci-app-nlbwmon=y" .config || echo "CONFIG_PACKAGE_luci-app-nlbwmon=y" >> .config

echo "[Customize Part 2] 后置配置完成"