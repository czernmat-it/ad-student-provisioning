<#
.SYNOPSIS
    Bulk creates Active Directory student accounts based on a CSV file.
    Places users into specific Year Group OUs (e.g., Year 6, Nursery).

.DESCRIPTION
    This script imports a CSV list of students and creates AD accounts.
    It automatically handles Organizational Unit (OU) paths based on the 'Year' column.
    It supports standard Year groups (1-6) and specific named groups like 'Nur' (Nursery).

.NOTES
    Author: Mateusz Czernecki
    Date: 2026-01-12
    Requirements: Active Directory PowerShell Module
#>

Import-Module ActiveDirectory

# --- CONFIGURATION ---
# Path to the source CSV file
$CsvFilePath = "C:\temp\users.csv"

# The root Parent OU where all student year groups are located
$ParentOU = "OU=Students,DC=domain,DC=internal"

# The User Principal Name (UPN) suffix for logins (e.g. @domain.internal)
$UPNSuffix = "@domain.internal"
# ---------------------

Write-Host "Starting User Creation Process..."
Write-Host "Reading CSV file from: $CsvFilePath"

try {
    $Users = Import-Csv -Path $CsvFilePath -ErrorAction Stop
}
catch {
    Write-Error "CRITICAL ERROR: Could not find or read the CSV file."
    Return
}

Write-Host "Found $(($Users).Count) users to process."
Write-Host "---------------------------------------------"

foreach ($User in $Users) {
    
    # 1. Validate Input Data
    if ([string]::IsNullOrWhiteSpace($User.Login)) {
        Write-Warning "Skipping row with missing Login."
        Continue
    }

    # 2. Prepare User Details
    $SamAccountName = $User.Login.Trim()
    $UserPrincipalName = "$SamAccountName$UPNSuffix"
    $DisplayName = $User.DisplayName.Trim()
    
    # 3. Determine Target OU (Logic for 'Nur' vs 'Year X')
    $YearGroup = $User.Year.Trim()
    
    if ($YearGroup -eq "Nur") {
        $FolderPrefix = "Nursery"
    }
    else {
        $FolderPrefix = "Year $YearGroup"
    }
    
    # Final path: OU=Nursery 2025-2026,OU=Students...
    $TargetOU = "OU=$FolderPrefix 2025-2026,$ParentOU"

    # 4. Prepare Password
    # Ensure Group Policy allows simple passwords if using 'abc'
    $SecurePassword = ConvertTo-SecureString $User.Password -AsPlainText -Force

    Write-Host "Processing: $SamAccountName ($FolderPrefix)" -NoNewline

    # 5. Check if user already exists
    if (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue) {
        Write-Host " - SKIPPED (Account already exists)" -ForegroundColor Yellow
    }
    else {
        try {
            New-ADUser -Name $DisplayName `
                       -DisplayName $DisplayName `
                       -GivenName $User.FirstName `
                       -Surname $User.LastName `
                       -SamAccountName $SamAccountName `
                       -UserPrincipalName $UserPrincipalName `
                       -Path $TargetOU `
                       -AccountPassword $SecurePassword `
                       -Enabled $true `
                       -ChangePasswordAtLogon $false `
                       -Description "Student - $FolderPrefix" `
                       -ErrorAction Stop
            
            Write-Host " - SUCCESS" -ForegroundColor Green
        }
        catch {
            Write-Host " - FAILED" -ForegroundColor Red
            Write-Error "Error details: $_"
            Write-Host "Verify that this OU exists: $TargetOU" -ForegroundColor Gray
        }
    }
}

Write-Host "---------------------------------------------"
Write-Host "Operation Complete."
