# Active Directory Automation & Monitoring Toolkit

This repository contains PowerShell scripts designed to automate and monitor tasks in an Active Directory environment. The project is divided into two main components:
# Active Directory Automation and Monitoring Project

This repository contains PowerShell scripts to automate Active Directory onboarding tasks and monitor system resources.

```plaintext
Active-Directory/
└── Onboarding-System/
    ├── Backup And Logs/                     # Contains log files generated during execution
    │   └── Events.log                       # Logs events like user creation, group mapping, etc.
    ├── Data/                                # Input data folder
    │   └── Data.csv                         # CSV file containing user and group data
    ├── GroupsFunc.ps1                       # Functions to manage and create AD groups
    ├── OrganizationalUnitsFunc.ps1          # Functions to manage and create Organizational Units
    ├── SharedFoldersAndMappingDrivs.ps1     # Creates shared folders and maps drives for users
    ├── UsersFunc.ps1                        # Functions for user creation and configuration
    └── main.ps1                             # Main script to execute the full onboarding process

└── Resources-Monitor/
    ├── SchedulerTask-Auto.ps1               # Create Scheduler Task         
    └── main.ps1                             # Script to monitor CPU/RAM usage across AD computers
     
```

## Descriptions of Files

### Onboarding-System/

- **Backup And Logs/Events.log**: This file logs events like user creation, group assignments, and other important actions in the onboarding process.
  
- **Data/Data.csv**: This file contains structured data about the users and groups to be managed in the Active Directory. It’s used as an input file for user and group creation.

- **GroupsFunc.ps1**: This PowerShell script is responsible for creating AD groups. It reads group data and executes commands to create groups in the Active Directory.

- **OrganizationalUnitsFunc.ps1**: This script is for creating Organizational Units (OUs) in Active Directory. It is useful for organizing users and groups into logical units.

- **SharedFoldersAndMappingDrivs.ps1**: This script automates the creation of shared folders and the mapping of these folders as drives for users in the Active Directory. It streamlines the process of assigning shared resources.

- **UsersFunc.ps1**: This script handles the creation of users in Active Directory, including setting up their properties like usernames, passwords, group memberships, etc.

- **main.ps1**: This is the main entry point script that executes all the other scripts (UsersFunc.ps1, GroupsFunc.ps1, etc.) in sequence to onboard users into Active Directory.

### Resources-Monitor/

- **main.ps1**: This script monitors the CPU and RAM usage of computers in the Active Directory. It collects performance data and logs the results.

## How to Use

1. Clone the repository to your local machine.
2. Navigate to the `Active-Directory/Onboarding-System/` directory.
3. Execute `main.ps1` to run the full onboarding process. This will create users, groups, and organizational units in Active Directory based on the data in `Data.csv`.
4. Monitor the resources using the script in `Resources-Monitor/main.ps1`, which tracks the performance metrics (CPU and RAM) of the computers.

---

## Requirements

- PowerShell 5.1 or later
- Active Directory module for PowerShell
- Access to a Windows Server with Active Directory configured

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


