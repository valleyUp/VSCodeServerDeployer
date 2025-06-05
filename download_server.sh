#!/bin/bash

# Display usage information
usage() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  -c, --commit-id COMMIT_ID   VS Code commit ID (必需)"
    echo "  -a, --arch ARCH             架构, 可选值: x64, arm64 (必需)"
    echo "  -e, --extensions            下载扩展"
    echo "  -f, --ext-file FILE         扩展配置文件路径，默认为 extensions.json"
    echo "  -h, --help                  显示帮助信息"
    exit 1
}

# Default values for parameters
commit_id=""
arch=""
download_extensions=false
extensions_file="extensions.json"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -c|--commit-id)
            commit_id="$2"
            shift 2
            ;;
        -a|--arch)
            if [[ "$2" == "x64" || "$2" == "arm64" ]]; then
                arch="$2"
            else
                echo "错误: 架构必须是 x64 或 arm64"
                usage
            fi
            shift 2
            ;;
        -e|--extensions)
            download_extensions=true
            shift
            ;;
        -f|--ext-file)
            extensions_file="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "未知选项: $1"
            usage
            ;;
    esac
done

# Verify required parameters
if [ -z "$commit_id" ]; then
    echo "错误: 缺少 commit ID"
    usage
fi

if [ -z "$arch" ]; then
    echo "错误: 缺少架构"
    usage
fi

# Check required tools
if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    echo "请安装 curl 和 tar"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "请安装 jq 用于 JSON 解析"
    exit 1
fi

# Check QEMU availability
if [ "$arch" = "arm64" ]; then
    if ! command -v qemu-aarch64-static >/dev/null 2>&1; then
        echo "请安装 QEMU 用于模拟 arm64 环境:"
        echo "Ubuntu/Debian: sudo apt-get install qemu-user-static"
        echo "Arch Linux: sudo pacman -S qemu-user-static"
        echo "CentOS/RHEL: sudo yum install qemu-user-static"
        exit 1
    fi
fi

# Set download URLs
url_server="https://vscode.download.prss.microsoft.com/dbazure/download/stable/${commit_id}/vscode-server-linux-${arch}.tar.gz"
url_cli="https://vscode.download.prss.microsoft.com/dbazure/download/stable/${commit_id}/vscode_cli_alpine_${arch}_cli.tar.gz"

# Create architecture specific directory
base_dir="./vscode-servers/${arch}"
work_dir="${base_dir}/${commit_id}"
mkdir -p "${work_dir}"
echo "工作目录: ${work_dir}"

# Download files if missing
server_file="${work_dir}/vscode-server-linux-${arch}.tar.gz"
if [ -f "${server_file}" ]; then
    echo "服务器包已存在，跳过下载..."
else
    echo "下载 vscode-server-linux-${arch}.tar.gz ..."
    curl -L -o "${server_file}" "${url_server}"
    if [ $? -ne 0 ]; then
        echo "下载 vscode-server-linux-${arch}.tar.gz 失败"
        exit 1
    fi
fi

cli_file="${work_dir}/vscode_cli_alpine_${arch}_cli.tar.gz"
if [ -f "${cli_file}" ]; then
    echo "CLI 包已存在，跳过下载..."
else
    echo "下载 vscode_cli_alpine_${arch}_cli.tar.gz ..."
    curl -L -o "${cli_file}" "${url_cli}"
    if [ $? -ne 0 ]; then
        echo "下载 vscode_cli_alpine_${arch}_cli.tar.gz 失败"
        exit 1
    fi
fi

# Extract files
echo "解压 vscode-server-linux-${arch}.tar.gz ..."
tar -zxf "${server_file}" -C "${work_dir}"
if [ $? -ne 0 ]; then
    echo "解压 vscode-server-linux-${arch}.tar.gz 失败"
    exit 1
fi

echo "解压 vscode_cli_alpine_${arch}_cli.tar.gz ..."
tar -zxf "${cli_file}" -C "${work_dir}"
if [ $? -ne 0 ]; then
    echo "解压 vscode_cli_alpine_${arch}_cli.tar.gz 失败"
    exit 1
fi

# Arrange directory structure
echo "组织目录结构 ..."

# Create .vscode-server directory
vscode_dir="${work_dir}/.vscode-server"
mkdir -p "${vscode_dir}/cli/servers/Stable-${commit_id}"
mkdir -p "${vscode_dir}/extensions"

# Move server folder, removing existing target first
server_dest="${vscode_dir}/cli/servers/Stable-${commit_id}/server"
if [ -d "$server_dest" ]; then
    echo "目标服务器目录已存在，正在清除..."
    rm -rf "$server_dest"
fi
mv "${work_dir}/vscode-server-linux-${arch}" "$server_dest"

# Move the code binary
mv "${work_dir}/code" "${vscode_dir}/code-${commit_id}"
chmod +x "${vscode_dir}/code-${commit_id}"

# Extension handling
if [ "$download_extensions" = true ]; then
    # Warn when running arm64 extensions on x86
    if [ "$arch" = "arm64" ]; then
        echo "警告: 当前在x86平台上运行，无法安装arm64架构的扩展。"
    fi

    # Create a template extension list if none exists
    if [ ! -f "$extensions_file" ]; then
        echo "创建新的 extensions.json 文件..."
        cat > "$extensions_file" << EOF
{
  "extensions": [
    {
      "id": "ms-python.python",
      "version": "latest"
    },
    {
      "id": "ms-azuretools.vscode-docker",
      "version": "latest"
    }
  ]
}
EOF
        echo "已创建包含示例扩展的 extensions.json"
        echo "请编辑此文件以包含所需的扩展，然后重新运行脚本"
        echo "格式: { \"extensions\": [ { \"id\": \"publisher.extensionName\", \"version\": \"specific_version_or_latest\" } ] }"
        exit 0
    fi

    # Read extensions from file
    echo "从 $extensions_file 读取扩展..."
    
    # Create extension directory
    mkdir -p "${vscode_dir}/extensions"
    
    # Download each extension
    jq -c '.extensions[]' "$extensions_file" | while read -r extension; do
        id=$(echo "$extension" | jq -r '.id')
        version=$(echo "$extension" | jq -r '.version')
        
        publisher=${id%%.*}
        name=${id#*.}
        
        echo "安装扩展: $id (版本: $version)"
        
        # 确定正确的版本参数
        if [ "$version" = "latest" ]; then
            version_param=""
        else
            version_param="@$version"
        fi
        
        # Install extension using the server binary
        # Enter vscode_dir first and call with relative path
        current_dir=$(pwd)
        cd "${work_dir}/.vscode-server"
        
        # Use custom data paths to avoid host VS Code config
        export VSCODE_CLI_DATA_DIR="./cli-data"
        export VSCODE_EXTENSIONS="./extensions" 
        export VSCODE_USER_DATA_DIR="./user-data"
        
        # Create temporary directories
        mkdir -p "./cli-data" "./user-data"
        
        # Run under QEMU when targeting arm64
        if [ "$arch" = "arm64" ]; then
            # Copy QEMU binary into working directory
            cp $(which qemu-aarch64-static) ./
            # Execute code binary via QEMU
            ./qemu-aarch64-static ./code-${commit_id} ext --extensions-dir "./extensions" --user-data-dir "./user-data" install --cli-data-dir "./cli/servers/Stable-${commit_id}/server" --force "${id}${version_param}"
            # Clean up QEMU binary
            rm ./qemu-aarch64-static
        else
            # Run directly on x64
            ./code-${commit_id} ext --extensions-dir "./extensions" --user-data-dir "./user-data" install --cli-data-dir "./cli/servers/Stable-${commit_id}/server" --force "${id}${version_param}"
        fi
        
        # Clean temporary directories
        rm -rf "./cli-data" "./user-data"
        
        # Return to original directory
        cd "$current_dir"
        
        if [ $? -ne 0 ]; then
            echo "安装扩展 $id 失败。跳过..."
            continue
        fi
        
        echo "成功安装 $id"
    done
fi

# Set permissions
echo "设置权限..."
chmod -R 700 "${vscode_dir}"

# Compress and package
output_file="vscode-server-${commit_id}-${arch}.tar.gz"
echo "压缩和打包 .vscode-server 目录到 ${output_file} ..."
tar -czf "${output_file}" -C "${work_dir}" ".vscode-server"
if [ $? -ne 0 ]; then
    echo "压缩和打包失败"
    exit 1
fi

echo "脚本完成。打包文件是 ${output_file}"

# Deployment instructions
cat << EOF

== 部署说明 ==

1. 将 ${output_file} 文件传输到您的离线服务器
2. 将其解压到用户的主目录:
   tar -xzf ${output_file} -C ~

3. 使用 VS Code Remote SSH 正常连接到服务器
   - 服务器二进制文件将自动被找到
   - 扩展将在 ~/.vscode-server/extensions 目录中可用

EOF
