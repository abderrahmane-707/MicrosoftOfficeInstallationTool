# MicrosoftOfficeInstallationTool

A simple interactive command-line tool for installing Microsoft Office.

## Features

- **Office Pack** — Word, Excel, PowerPoint, Outlook, OneNote, Publisher, Access, Visio, Project, Proofing Tools, Teams, OneDrive
- **Version** — Office 365, 2021, 2019, 2016
- **Language** — English (en-us) / Arabic (ar-sa)
- **Installation mode**
  - Online Installation
  - Download Offline Files
  - Offline Installation (using previously downloaded files)
- **Auto-detects** System architecture (32/64-bit, including ARM64)
- **Activation** Activate the package using (MAS) script
- **Privacy** Automatically disables Office Telemetry after installation

## Usage

1. Clone the repository:
```cmd
git clone https://github.com/abderrahmane-707/MicrosoftOfficeInstallationTool.git
```
2. Right-click `office.bat` and choose **Run as administrator**.
3. Use the number keys to select/deselect the apps you want (e.g. `1,3,5` or `1-5`).
4. Press `V` to change the Office version, `L` to change the language, `M` to toggle Online/Offline mode.
5. Press `A` to select all apps, `D` to deselect all.
6. Press `S` to start, then confirm to begin the installation.
