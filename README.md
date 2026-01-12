# Active Directory Bulk Student Provisioning

This repository contains a PowerShell script designed to automate the creation of student accounts in Microsoft Active Directory. It is tailored for educational environments where students are organized into Organizational Units (OUs) based on their Year Group (e.g., Year 1, Year 6, Nursery).

## Features

* **Bulk Creation:** Processes hundreds of accounts from a single CSV file.
* **Dynamic OU Placement:** Automatically routes students to the correct OU based on their year group.
* **Custom Login Support:** Uses pre-defined login names from the CSV to ensure accuracy.
* **Duplicate Prevention:** Checks if a username exists before attempting creation.
* **Special Case Handling:** Includes logic to map "Nur" to a "Nursery" folder, while keeping standard years as "Year X".

## Prerequisites

1.  **Windows Server:** A Domain Controller or a workstation with RSAT (Remote Server Administration Tools) installed.
2.  **PowerShell:** Active Directory module must be available.
3.  **Permissions:** The account running the script must have 'Create User Objects' permissions in the target OUs.
4.  **Password Policy:** If using simple passwords (e.g., "abc") for primary students, ensure the Domain Password Policy or Fine-Grained Password Policy allows this (Minimum password length: 0, Complexity: Disabled).

## Configuration

Open `Create-Students.ps1` and modify the configuration section to match your environment:

```powershell
$CsvFilePath = "C:\temp\students.csv"
$ParentOU = "OU=Students,DC=school,DC=local"
$UPNSuffix = "@school.local"
