# VS Code Server Deployer

## Overview
This repository provides a bash script for downloading the VS Code Server files for a specific commit and packaging them for offline installation. It can optionally fetch extensions defined in a JSON file. A GitHub Action workflow is included to automatically build and publish archives for `x64` and `arm64` architectures.

## Usage
### Requirements
- `curl`, `tar` and `jq` must be available
- QEMU is required when creating an `arm64` package on an `x64` host

### Script
```bash
./download_server.sh -c <commit_id> -a <x64|arm64> [-e] [-f extensions.json]
```

Options:
- `-c`, `--commit-id` – VS Code commit id
- `-a`, `--arch` – target architecture (`x64` or `arm64`)
- `-e`, `--extensions` – also download extensions
- `-f`, `--ext-file` – extension list file (default `extensions.json`)

The script produces `vscode-server-<commit_id>-<arch>.tar.gz`. Extract this archive to the home directory of the target machine and connect using VS Code Remote SSH.

## GitHub Action
The workflow in `.github/workflows/download-vscode-server.yml` runs monthly or can be dispatched manually. It downloads the latest commit, packages both architectures, and uploads them as release assets.

---

# VS Code Server 离线部署脚本

## 概述
该仓库提供了一个 Bash 脚本，用于根据指定的 commit 下载 VS Code Server，并可选地按照 JSON 文件中的列表下载扩展，最终打包成离线安装包。同时仓库内包含的 GitHub Action 工作流可以自动下载并发布 x64 与 arm64 两种架构的压缩包。

## 使用方法
### 依赖
- 需要安装 `curl`、`tar` 和 `jq`
- 若在 x64 主机上生成 arm64 包，需要额外安装 QEMU

### 脚本运行
```bash
./download_server.sh -c <commit_id> -a <x64|arm64> [-e] [-f extensions.json]
```
参数说明：
- `-c`/`--commit-id`：VS Code 的 commit ID（必填）
- `-a`/`--arch`：目标架构，可为 `x64` 或 `arm64`
- `-e`/`--extensions`：同时下载扩展
- `-f`/`--ext-file`：扩展列表文件，默认为 `extensions.json`

脚本执行后会生成 `vscode-server-<commit_id>-<arch>.tar.gz`，将其解压到目标服务器的用户主目录即可通过 VS Code Remote SSH 连接。

## GitHub Action
`.github/workflows/download-vscode-server.yml` 每月自动运行，也可手动触发，负责下载最新 commit 的服务器文件并打包两种架构，作为 Release 附件发布。
