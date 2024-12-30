# VS Code Server Offline Deployment Script

This script automates the process of downloading and preparing the necessary files for offline deployment of VS Code Server. It allows you to download the required VS Code Server and CLI components based on a specific commit ID, and then packages them into a single `tar.gz` archive for easy transfer and deployment to an offline server environment.

## Features

*   Downloads VS Code Server and CLI for either x86 (x64) or ARM (arm64) architectures.
*   Retrieves files based on a user-provided VS Code commit ID.
*   Organizes files into the correct `.vscode-server` directory structure.
*   Sets appropriate file permissions for security.
*   Creates a compressed `tar.gz` archive for easy offline deployment.

## Prerequisites

*   **curl**: Used for downloading files.
*   **tar**: Used for extracting and creating archives.
