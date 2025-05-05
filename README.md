# Automation IT Administration

This repository contains scripts for automating IT administrative tasks, with a focus on **Active Directory** management and **User Onboarding**. The goal is to simplify and automate routine IT processes to improve efficiency and reduce manual errors.

## Table of Contents
1. [Overview](#overview)
2. [Features](#features)
3. [Prerequisites](#prerequisites)
4. [Installation](#installation)
5. [Usage](#usage)
6. [License](#license)

## Overview

This project focuses on automating IT administration tasks, starting with **Active Directory** user management and **Onboarding** automation. It is designed to streamline the process of managing user accounts, permissions, and related administrative tasks in an IT environment.

### Future Plans

The project will expand to include additional automation tasks such as:

- **Azure AD Management**
- **System Monitoring**
- **Cloud Infrastructure Automation**

## Features

- **Onboarding System**: Automates the user onboarding process, including creating new user accounts in Active Directory.
- **Active Directory Management**: Simplifies common tasks like user creation, group assignments, and permissions management.
- **PowerShell Automation**: All scripts are written in PowerShell to automate routine IT tasks in a Windows environment.

## Prerequisites

To use the scripts in this repository, ensure you have the following installed:

- **PowerShell**: The automation scripts are written in PowerShell.
- **Active Directory Module**: Required for interacting with Active Directory.
  - You can install it using the command:  
    ```powershell
    Install-WindowsFeature RSAT-AD-PowerShell
    ```
- **Administrator Permissions**: Some tasks may require administrative privileges.

## Installation

1. Clone the repository to your local machine:

   ```bash
   git clone https://github.com/senani-derradji/Automation-IT-Administration.git