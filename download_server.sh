#!/bin/bash

# Script Description
echo "This script automates the download of VS Code Server and its extensions for offline deployment."

# Check if curl, tar, and jq are installed
if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    echo "Please install curl and tar."
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "Please install jq for JSON parsing."
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

# Create necessary directories in current path
work_dir="./vscode-server-${commit_id}-${arch}"
mkdir -p "${work_dir}"
echo "Working directory: ${work_dir}"

# Download files if they don't exist
server_file="${work_dir}/vscode-server-linux-${arch}.tar.gz"
if [ -f "${server_file}" ]; then
    echo "Server package already exists, skipping download..."
else
    echo "Downloading vscode-server-linux-${arch}.tar.gz ..."
    curl -L -o "${server_file}" "${url_server}"
    if [ $? -ne 0 ]; then
        echo "Failed to download vscode-server-linux-${arch}.tar.gz."
        rm -rf "${work_dir}"
        exit 1
    fi
fi

cli_file="${work_dir}/vscode_cli_alpine_${arch}_cli.tar.gz"
if [ -f "${cli_file}" ]; then
    echo "CLI package already exists, skipping download..."
else
    echo "Downloading vscode_cli_alpine_${arch}_cli.tar.gz ..."
    curl -L -o "${cli_file}" "${url_cli}"
    if [ $? -ne 0 ]; then
        echo "Failed to download vscode_cli_alpine_${arch}_cli.tar.gz."
        rm -rf "${work_dir}"
        exit 1
    fi
fi

# Extract files
echo "Extracting vscode-server-linux-${arch}.tar.gz ..."
tar -zxf "${server_file}" -C "${work_dir}"
if [ $? -ne 0 ]; then
    echo "Failed to extract vscode-server-linux-${arch}.tar.gz."
    rm -rf "${work_dir}"
    exit 1
fi

echo "Extracting vscode_cli_alpine_${arch}_cli.tar.gz ..."
tar -zxf "${cli_file}" -C "${work_dir}"
if [ $? -ne 0 ]; then
    echo "Failed to extract vscode_cli_alpine_${arch}_cli.tar.gz."
    rm -rf "${work_dir}"
    exit 1
fi

# Organize directory structure
echo "Organizing directory structure ..."

# Create .vscode-server directory
vscode_dir="${work_dir}/.vscode-server"
mkdir -p "${vscode_dir}/cli/servers/Stable-${commit_id}"
mkdir -p "${vscode_dir}/extensions"

# Move server folder
mv "${work_dir}/vscode-server-linux-${arch}" "${vscode_dir}/cli/servers/Stable-${commit_id}/server"

# Copy code file
cp "${work_dir}/code" "${vscode_dir}/code-${commit_id}"

# Extension handling
echo "Do you want to download extensions? (y/n)"
read -r download_extensions

if [ "$download_extensions" = "y" ]; then
    extensions_file="extensions.json"
    
    # Check if the extensions file exists, if not, create one
    if [ ! -f "$extensions_file" ]; then
        echo "Creating a new extensions.json file..."
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
        echo "Created extensions.json with sample extensions."
        echo "Please edit this file to include your required extensions and run the script again."
        echo "Format: { \"extensions\": [ { \"id\": \"publisher.extensionName\", \"version\": \"specific_version_or_latest\" } ] }"
        rm -rf "${work_dir}"
        exit 0
    fi

    # Read from extensions file
    echo "Reading extensions from $extensions_file ..."
    
    # Create extensions directory
    mkdir -p "${vscode_dir}/extensions"
    
    # VS Code marketplace URL
    marketplace_url="https://marketplace.visualstudio.com/_apis/public/gallery/publishers"
    
    # Download each extension
    jq -c '.extensions[]' "$extensions_file" | while read -r extension; do
        id=$(echo "$extension" | jq -r '.id')
        version=$(echo "$extension" | jq -r '.version')
        
        publisher=${id%%.*}
        name=${id#*.}
        
        echo "Installing extension: $id (version: $version)"
        
        # Determine correct version parameter
        if [ "$version" = "latest" ]; then
            version_param=""
        else
            version_param="@$version"
        fi
        
        # Use the local code binary to install the extension
        "${vscode_dir}/code-${commit_id}" --extensions-dir "${vscode_dir}/extensions" --install-extension "${id}${version_param}"
        
        if [ $? -ne 0 ]; then
            echo "Failed to install extension $id. Skipping..."
            continue
        fi
        
        echo "Successfully installed $id"
    done
fi

# Set permissions
echo "Setting permissions ..."
chmod -R 700 "${vscode_dir}"

# Compress and package
echo "Compressing and packaging .vscode-server directory ..."
tar -czf "vscode-server-${commit_id}-${arch}.tar.gz" -C "${work_dir}" ".vscode-server"
if [ $? -ne 0 ]; then
    echo "Failed to compress and package."
    rm -rf "${work_dir}"
    exit 1
fi

# Clean up temporary directory
rm -rf "${work_dir}"

echo "Script completed. The packaged file is vscode-server-${commit_id}-${arch}.tar.gz"

# Deployment instructions
cat << EOF

== Deployment Instructions ==

1. Transfer the vscode-server-${commit_id}-${arch}.tar.gz file to your offline server
2. Extract it to the user's home directory:
   tar -xzf vscode-server-${commit_id}-${arch}.tar.gz -C ~

3. Connect to the server normally with VS Code Remote SSH
   - The server binary will be found automatically
   - The extensions will be available in the ~/.vscode-server/extensions directory

EOF