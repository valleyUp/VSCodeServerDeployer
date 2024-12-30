#!/bin/bash

# Script Description
echo "This script automates the download and offline deployment of the required files for VS Code Server."

# Check if curl and tar are installed
if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    echo "Please install curl and tar."
    exit 1
fi

# Get the VS Code commit_id
echo "Please find the commit_id in your VS Code client (Help -> About), then enter the commit_id:"
read -r commit_id
if [ -z "$commit_id" ]; then
    echo "commit_id cannot be empty."
    exit 1
fi

# Determine the architecture (x86 or arm)
echo "Select server architecture:"
echo "1) x86"
echo "2) arm"
read -r choice
case $choice in
    1)
        arch="x64"
        url_server="https://vscode.download.prss.microsoft.com/dbazure/download/stable/${commit_id}/vscode-server-linux-x64.tar.gz"
        url_cli="https://vscode.download.prss.microsoft.com/dbazure/download/stable/${commit_id}/vscode_cli_alpine_x64_cli.tar.gz"
        ;;
    2)
        arch="arm64"
        url_server="https://vscode.download.prss.microsoft.com/dbazure/download/stable/${commit_id}/vscode-server-linux-arm64.tar.gz"
        url_cli="https://vscode.download.prss.microsoft.com/dbazure/download/stable/${commit_id}/vscode_cli_alpine_arm64_cli.tar.gz"
        ;;
    *)
        echo "Invalid choice, exiting script."
        exit 1
        ;;
esac

# Create a temporary directory
temp_dir=$(mktemp -d)
echo "Temporary directory: ${temp_dir}"

# Download files
echo "Downloading vscode-server-linux-${arch}.tar.gz ..."
curl -L -o "${temp_dir}/vscode-server-linux-${arch}.tar.gz" "${url_server}"
if [ $? -ne 0 ]; then
    echo "Failed to download vscode-server-linux-${arch}.tar.gz."
    rm -rf "${temp_dir}"
    exit 1
fi

echo "Downloading vscode_cli_alpine_${arch}_cli.tar.gz ..."
curl -L -o "${temp_dir}/vscode_cli_alpine_${arch}_cli.tar.gz" "${url_cli}"
if [ $? -ne 0 ]; then
    echo "Failed to download vscode_cli_alpine_${arch}_cli.tar.gz."
    rm -rf "${temp_dir}"
    exit 1
fi

# Extract files
echo "Extracting vscode-server-linux-${arch}.tar.gz ..."
tar -zxf "${temp_dir}/vscode-server-linux-${arch}.tar.gz" -C "${temp_dir}"
if [ $? -ne 0 ]; then
    echo "Failed to extract vscode-server-linux-${arch}.tar.gz."
    rm -rf "${temp_dir}"
    exit 1
fi

echo "Extracting vscode_cli_alpine_${arch}_cli.tar.gz ..."
tar -zxf "${temp_dir}/vscode_cli_alpine_${arch}_cli.tar.gz" -C "${temp_dir}"
if [ $? -ne 0 ]; then
    echo "Failed to extract vscode_cli_alpine_${arch}_cli.tar.gz."
    rm -rf "${temp_dir}"
    exit 1
fi

# Organize directory structure
echo "Organizing directory structure ..."

# Create .vscode-server directory
vscode_dir="${temp_dir}/.vscode-server"
mkdir -p "${vscode_dir}/cli/servers/Stable-${commit_id}"

# Move server folder
mv "${temp_dir}/vscode-server-linux-${arch}" "${vscode_dir}/cli/servers/Stable-${commit_id}/server"

# Copy code file
cp "${temp_dir}/code" "${vscode_dir}/code-${commit_id}"

# Set permissions
echo "Setting permissions ..."
chmod -R 700 "${vscode_dir}"

# Compress and package
echo "Compressing and packaging .vscode-server directory ..."
tar -czf "vscode-server-${commit_id}-${arch}.tar.gz" -C "${temp_dir}" ".vscode-server"
if [ $? -ne 0 ]; then
    echo "Failed to compress and package."
    rm -rf "${temp_dir}"
    exit 1
fi

# Clean up temporary directory
rm -rf "${temp_dir}"

echo "Script completed. The packaged file is vscode-server-${commit_id}-${arch}.tar.gz"
