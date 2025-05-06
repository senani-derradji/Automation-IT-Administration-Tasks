# IT Administration Automation – Active Directory Onboarding System

This repository is dedicated to automating routine IT administrative tasks using PowerShell. It currently includes ..., a system for onboarding users into Active Directory, with functionality for managing users, groups, organizational units, shared folders, and drive mappings.

📁 **Repository Structure**
```
Active-Directory/
└── Onboarding-System/
    ├── Backup And Logs/
    │   └── Events.log
    ├── Data/
    │   └── Data.csv
    ├── GroupsFunc.ps1
    ├── OrganizationalUnitsFunc.ps1
    ├── SharedFoldersAndMappingDrivs.ps1
    ├── UsersFunc.ps1
    └── main.ps1
.
..
...
```

---

## 🚀 Features

- **User Provisioning** – Automated user creation via `UsersFunc.ps1` using data from CSV.
- **Group Management** – Create and manage security groups with `GroupsFunc.ps1`.
- **Organizational Units (OU)** – Automated OU structure creation via `OrganizationalUnitsFunc.ps1`.
- **Drive Mapping** – Configure shared folders and assign network drives using `SharedFoldersAndMappingDrivs.ps1`.
- **Logging** – Logs activities in `Backup And Logs/Events.log`.
- **Data-Driven** – Imports user and group data from `Data/Data.csv`.

---

## ▶️ Getting Started

### Prerequisites

- Windows OS with administrative privileges
- PowerShell 5.1+
- Active Directory module installed (`RSAT` tools)
- Execution policy allowing script execution:
  ```powershell
  Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
  ```

### Running the Script

1. Clone the repository:
   ```bash
   git clone https://github.com/senani-derradji/Automation-IT-Administration-Tasks.git
   ```

2. Navigate to the `Onboarding-System` folder:
   ```bash
   cd Active-Directory/Onboarding-System
   ```

3. Run the main onboarding script:
   ```powershell
   .\main.ps1
   ```

> The `main.ps1` script orchestrates calls to each of the function files. Make sure the CSV and other configuration files are prepared.

---

## 📌 Notes

- Keep `Data/Data.csv` updated with accurate user information.
- Check `Events.log` for execution history and troubleshooting.
- Script structure allows easy expansion with more PowerShell modules.

---

## 🛠️ Roadmap

- [ ] Add user offboarding functionality
- [ ] Integrate email notifications
- [ ] Add GUI interface for onboarding
- [ ] Extend support for Azure AD

---

## 🤝 Contributing

Pull requests are welcome! Please fork the repository and submit your additions to expand automation functionality.

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).