#!/bin/bash
# ========================================
# 编译前自定义脚本 Part 1
# 在 ./scripts/feeds install -a 之后、make 之前运行
# ========================================

echo "[Customize Part 1] 开始配置..."

# ========== 网络功能 ==========

# 启用 IPv6
sed -i 's/# CONFIG_PACKAGE_luci-proto-ipv6 is not set/CONFIG_PACKAGE_luci-proto-ipv6=y/g' .config

# 启用 BBR 拥塞控制 (提升网络性能)
grep -q "CONFIG_PACKAGE_kmod-tcp-bbr=y" .config || echo "CONFIG_PACKAGE_kmod-tcp-bbr=y" >> .config

# 启用 BBRv2 (更好兼容性)
grep -q "CONFIG_PACKAGE_kmod-tcp-bbr2=y" .config || echo "CONFIG_PACKAGE_kmod-tcp-bbr2=y" >> .config

# 启用 QoS 流量控制
grep -q "CONFIG_PACKAGE_luci-app-qos=y" .config || echo "CONFIG_PACKAGE_luci-app-qos=y" >> .config

# ========== 流量卸载优化 (flow-offload) ==========

# 连接跟踪加速
grep -q "CONFIG_PACKAGE_kmod-nf-flow=y" .config || echo "CONFIG_PACKAGE_kmod-nf-flow=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-ipt-offload=y" .config || echo "CONFIG_PACKAGE_kmod-ipt-offload=y" >> .config

# nftables flow offload
grep -q "CONFIG_PACKAGE_kmod-nft-offload=y" .config || echo "CONFIG_PACKAGE_kmod-nft-offload=y" >> .config

# ========== NPU 硬件加速 (Airoha AN7581) ==========

grep -q "CONFIG_PACKAGE_kmod-airoha-npu=y" .config || echo "CONFIG_PACKAGE_kmod-airoha-npu=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-netdev=y" .config || echo "CONFIG_PACKAGE_kmod-netdev=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-sched-core=y" .config || echo "CONFIG_PACKAGE_kmod-sched-core=y" >> .config

# ========== WiFi 7 (MT7996) + MLO 支持 ==========

grep -q "CONFIG_PACKAGE_kmod-mt7996e=y" .config || echo "CONFIG_PACKAGE_kmod-mt7996e=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-mt7921e=y" .config || echo "CONFIG_PACKAGE_kmod-mt7921e=y" >> .config
grep -q "CONFIG_PACKAGE_wpad-openssl=y" .config || echo "CONFIG_PACKAGE_wpad-openssl=y" >> .config

# ========== 10G 万兆网口驱动 ==========

grep -q "CONFIG_PACKAGE_kmod-phy-airoha=y" .config || echo "CONFIG_PACKAGE_kmod-phy-airoha=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-gsw-airoha=y" .config || echo "CONFIG_PACKAGE_kmod-gsw-airoha=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-airoha-enet-phy=y" .config || echo "CONFIG_PACKAGE_kmod-airoha-enet-phy=y" >> .config

# ========== DSCP offload QoS ==========

grep -q "CONFIG_PACKAGE_kmod-ipt-dscp=y" .config || echo "CONFIG_PACKAGE_kmod-ipt-dscp=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-ipt-dscp=y" .config || echo "CONFIG_PACKAGE_kmod-ipt-dscp=y" >> .config
grep -q "CONFIG_PACKAGE_iptables-mod-dscp=y" .config || echo "CONFIG_PACKAGE_iptables-mod-dscp=y" >> .config
grep -q "CONFIG_PACKAGE_iptables-mod-ecn=y" .config || echo "CONFIG_PACKAGE_iptables-mod-ecn=y" >> .config
grep -q "CONFIG_PACKAGE_kmod-act-sample=y" .config || echo "CONFIG_PACKAGE_kmod-act-sample=y" >> .config

# ========== 系统优化 ==========

# 启用 OpenSSH
sed -i 's/# CONFIG_PACKAGE_luci-app-openssh is not set/CONFIG_PACKAGE_luci-app-openssh=y/g' .config

# 设置时区为中国 (CST-8)
sed -i 's/# CONFIG_TIME_ZONE is not set/CONFIG_TIME_ZONE="CST-8"/g' .config

echo "[Customize Part 1] 配置完成"