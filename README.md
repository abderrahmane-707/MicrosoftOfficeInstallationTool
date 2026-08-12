# MicrosoftOfficeInstallationTool

A simple interactive command-line tool (Windows Batch) for installing Microsoft Office.
Pick the apps you want, choose a version, language, and installation mode,
then let the script generate the Office Deployment Tool configuration and run the install for you.

## Features

- **Pick apps individually** — Word, Excel, PowerPoint, Outlook, OneNote, Publisher, Access, Visio, Project, Proofing Tools, Teams, OneDrive
- **Flexible selection syntax** — select items by number, range, or a mix (e.g. `1,3,5` or `1-5` or `1-3,7,10-12`)
- **Select All / Deselect All** shortcuts
- **Version toggle** — Office 365, 2021, 2019, 2016
- **Language toggle** — English (en-us) / Arabic (ar-sa)
- **Installation mode**
  - Online Installation
  - Download Offline Files
  - Offline Installation (using previously downloaded files)
  - Delete Offline Files
- **Auto-detects** system architecture (32/64-bit, including ARM64)
- Automatically disables Office Telemetry after installation

## Usage

1. Right-click `office.bat` and choose **Run as administrator**.
2. Use the number keys to select/deselect the apps you want (e.g. `1,3,5` or `1-5`).
3. Press `V` to change the Office version, `L` to change the language, `M` to toggle Online/Offline mode.
4. Press `A` to select all apps, `D` to deselect all.
5. Press `S` to start, then confirm to begin the installation.
