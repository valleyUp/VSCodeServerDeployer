# VS Code Server Deployer

## Overview
This repository provides a bash script for downloading the VS Code Server/CLI files for a specific commit and packaging them for offline installation. Extension preinstallation uses the official server-side CLI (`code-server --install-extension`, no long-running server) so extensions are installed the same way VS Code does without blocking. A GitHub Action workflow is included to automatically build and publish archives for `x64` and `arm64` architectures.

## Usage
### Requirements
- `curl`, `tar`, `jq` must be available
- When building an `arm64` package on `x64`, `qemu-aarch64-static` is required

### Script
```bash
./download_server.sh -c <commit_id> -a <x64|arm64> [-e] [-f extensions.json]
```

Options:
- `-c`, `--commit-id` – VS Code commit id
- `-a`, `--arch` – target architecture (`x64` or `arm64`)
- `-e`, `--extensions` – download and preinstall extensions
- `-f`, `--ext-file` – extension list file (default `extensions.json`)

Notes:
- Extensions are installed via the official server-side CLI (`code-server --install-extension`, no persistent server) into `.vscode-server/extensions`, using isolated `user-data` and `server-data` inside the archive.

The script produces `vscode-server-<commit_id>-<arch>.tar.gz`. Extract this archive to the home directory of the target machine and connect using VS Code Remote SSH. If `-e` is used, extensions are already present; otherwise install via VS Code online or sync.

## GitHub Action
The workflow in `.github/workflows/download-vscode-server.yml` runs monthly or can be dispatched manually. It downloads the latest commit, packages both architectures, and uploads them as release assets.

---

# VS Code Server 离线部署脚本

## 概述
该仓库提供了一个 Bash 脚本，用于根据指定的 commit 下载 VS Code Server 与 CLI，并打包成离线安装包。扩展预装调用官方的 server 端 CLI，与 VS Code 的安装行为保持一致。仓库内包含的 GitHub Action 工作流可以自动下载并发布 x64 与 arm64 两种架构的压缩包。

## 使用方法
### 依赖
- 需要安装 `curl`、`tar`、`jq`
- 若在 x64 主机上生成 arm64 包，需要额外安装 `qemu-aarch64-static`

### 脚本运行
```bash
./download_server.sh -c <commit_id> -a <x64|arm64> [-e] [-f extensions.json]
```
参数说明：
- `-c`/`--commit-id`：VS Code 的 commit ID（必填）
- `-a`/`--arch`：目标架构，可为 `x64` 或 `arm64`
- `-e`/`--extensions`：下载并预装扩展
- `-f`/`--ext-file`：扩展列表文件，默认为 `extensions.json`

说明：
- 脚本调用官方 server 端 CLI（`code-server --install-extension`，无需常驻 server）安装扩展，使用归档内的独立 `user-data` 与 `server-data` 目录。

脚本执行后会生成 `vscode-server-<commit_id>-<arch>.tar.gz`，将其解压到目标服务器的用户主目录即可通过 VS Code Remote SSH 连接；若指定了 `-e`，扩展已预装完毕，否则请在联网环境下安装/同步。

## GitHub Action
`.github/workflows/download-vscode-server.yml` 每月自动运行，也可手动触发，负责下载最新 commit 的服务器文件并打包两种架构，作为 Release 附件发布。
