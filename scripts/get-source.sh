#!/bin/bash
# ========================================
# 获取上游源代码脚本 (本地编译用)
# ========================================

set -e

UPSTREAM=${1:-immortalwrt}
BRANCH=${2:-openwrt-25.12}

echo "========================================"
echo "Gemtek XR1710G 固件编译环境准备"
echo "========================================"

# 检查系统
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "⚠️  仅支持 Linux 系统"
    exit 1
fi

# 安装依赖 (Ubuntu/Debian)
install_dependencies() {
    echo "🔧 安装编译依赖..."

    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y \
            build-essential clang flex bison g++ awk \
            libncurses-dev libncurses5-dev libz-dev libssl-dev \
            zlib1g-dev zlib1g-dev gettext libncurses5-dev \
            git git-lfs subversion ca-certificates python3 python3-distutils
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y \
            git gettext libncurses5-dev zlib-devel python3
    fi

    echo "✅ 依赖安装完成"
}

# 安装自定义插件
install_custom_packages() {
    echo "📦 安装自定义插件..."
    local build_dir=$1

    # 复制自定义插件到源码目录
    if [ -d "../package/custom" ]; then
        cp -r ../package/custom $build_dir/package/
        echo "✅ 自定义插件已复制"
    else
        echo "⚠️  未找到 package/custom 目录，跳过"
    fi
}

# 配置 DIY 脚本
install_diy_scripts() {
    echo "📦 链接 DIY 脚本..."
    local build_dir=$1

    # 复制 diy 脚本
    if [ -d "../config" ]; then
        mkdir -p $build_dir/diy
        cp ../config/diy-part1.sh $build_dir/diy/
        cp ../config/diy-part2.sh $build_dir/diy/
        chmod +x $build_dir/diy/*.sh
        echo "✅ DIY 脚本已复制"
    fi
}

# 获取 iStoreOS 源码
get_istoreos() {
    echo "📦 克隆 iStoreOS 源码..."
    if [ -d "istoreos" ]; then
        echo "📁 istoreos 目录已存在，跳过克隆"
        cd istoreos && git pull
        cd ..
    else
        git clone --depth=1 -b $BRANCH https://github.com/istoreos/istoreos.git istoreos
    fi
    echo "✅ iStoreOS 源码就绪"
}

# 获取 ImmortalWrt 源码
get_immortalwrt() {
    echo "📦 克隆 ImmortalWrt 源码..."
    if [ -d "immortalwrt" ]; then
        echo "📁 immortalwrt 目录已存在，跳过克隆"
        cd immortalwrt && git pull
        cd ..
    else
        git clone --depth=1 -b $BRANCH https://github.com/immortalwrt/immortalwrt.git
    fi
    echo "✅ ImmortalWrt 源码就绪"
}

# 获取 OpenWrt 源码
get_openwrt() {
    echo "📦 克隆 OpenWrt 源码..."
    if [ -d "openwrt" ]; then
        echo "📁 openwrt 目录已存在，跳过克隆"
        cd openwrt && git pull
        cd ..
    else
        git clone --depth=1 -b $BRANCH https://github.com/openwrt/openwrt.git
    fi
    echo "✅ OpenWrt 源码就绪"
}

# 安装 feeds
setup_feeds() {
    local dir=$1
    echo "📦 更新 Feeds..."
    cd $dir
    ./scripts/feeds update -a
    ./scripts/feeds install -a
    cd ..
    echo "✅ Feeds 配置完成"
}

# 运行 DIY 脚本
run_diy_scripts() {
    local dir=$1
    echo "📦 运行自定义配置脚本..."
    cd $dir

    # Part 1: feeds install 之后
    if [ -f "diy/diy-part1.sh" ]; then
        source diy/diy-part1.sh
    fi

    cd ..
    echo "✅ DIY 配置完成"
}

# 安装依赖
install_dependencies

# 获取源码
case $UPSTREAM in
    istoreos)
        get_istoreos
        SOURCE_DIR="istoreos"
        ;;
    immortalwrt)
        get_immortalwrt
        SOURCE_DIR="immortalwrt"
        ;;
    openwrt)
        get_openwrt
        SOURCE_DIR="openwrt"
        ;;
    all)
        get_istoreos
        get_immortalwrt
        get_openwrt
        SOURCE_DIR=""
        ;;
    *)
        echo "❌ 未知的上游版本: $UPSTREAM"
        echo "   可选: istoreos | immortalwrt | openwrt | all"
        exit 1
        ;;
esac

# 配置 feeds
if [ -n "$SOURCE_DIR" ]; then
    setup_feeds $SOURCE_DIR
    install_custom_packages $SOURCE_DIR
    install_diy_scripts $SOURCE_DIR
fi

echo ""
echo "========================================"
echo "✅ 环境准备完成！"
echo "========================================"
echo ""
echo "当前配置："
echo "  - 上游版本: $UPSTREAM"
echo "  - 分支: $BRANCH"
echo "  - 源码目录: $SOURCE_DIR"
echo ""
echo "下一步操作："
echo "  1. cd $SOURCE_DIR"
echo "  2. source diy/diy-part1.sh              # 运行第一阶段配置"
echo "  3. make menuconfig"
echo "     → Target System: Airoha ARM64"
echo "     → Subtarget: AN7581"
echo "     → Target Profile: Gemtek XR1710G"
echo "  4. source ../diy/diy-part2.sh          # 运行第二阶段配置"
echo "  5. make -j\$(nproc)"
echo ""
echo "提示：编辑 ../config/plugins.conf 自定义插件组合"
echo ""