<#
.SYNOPSIS
    Adds Azure AD Users to an Azure AD Group. 

.DESCRIPTION
    Adds Azure AD User to an Azure AD Group. Users can be provided using an array or text file containing user email addresses. 

.PARAMETER GroupName
    Set name of group to add users to. If only part of the group name is know script will display a list of group names
    to chose from. 

.PARAMETER User
    Sets users to add. Use user's email address.

.PARAMETER Path
    Sets path to text file containing users to add. Use user's email address.

.EXAMPLE
    Add User from list of emails to Azure AD Group.

    .\Add-AzureADGroupMembers.ps1 -Users user1@contoso.com,user2@contoso.com,user3@contoso.com -GroupName "HR Assistant"
.EXAMPLE
    Add Users from text file of emails to Azure AD Group.

    .\Add-AzureADGroupMembers.ps1 -Path C:\Temp\userEmails.txt -GroupName "HR Assistant"
.EXAMPLE
    Add Users from text file of emails to Azure AD Group where group name is not fully known. Shows list of groups
    to chose and select. (select only 1 group)

    .\Add-AzureADGroupMember.ps1 -Path C:\Temp\userEmails.txt -GroupName "HR"
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [String]$GroupName,

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [String[]]$User, 

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.IO.FileInfo]$Path
)

try {
    Connect-AzureAD -ErrorAction Stop
} catch {
    Write-Output "Could not connect to Azure AD. $($_)"
}

try {
    $Group = Get-AzureADGroup -SearchString $GroupName -ErrorAction Stop
} catch {
    Write-Output "could not retrieve group information for $($GroupName). $($_)"
}

if($Group.Count -gt 1) {

    try {
        $Selection = $Group | Out-GridView -PassThru -Title 'Select a Group' -ErrorAction Stop
        $SelectedGroup = $Selection
    } catch {
        Write-Output "Multiple groups found, could not display the group information. $($_)"
    }
} else {
    $SelectedGroup = $Group
}

if($Path) {
    try {
        $Users = Get-Content -Path $Path -ErrorAction Stop
    } catch {
        Write-Output "Could not get the list of users. $($_)"
    }
} else {
    $Users = $User
}

$Users | ForEach-Object {
    if (Get-AzureADUser -Filter "Mail eq '$($_)'" -ErrorAction SilentlyContinue) {
        try {
            $uObj = (Get-AzureADUser -Filter "Mail eq '$($_)'").ObjectId
            $mGroup = $SelectedGroup.ObjectId
            Write-Output "Adding $($_) to $($SelectedGroup.DisplayName)"
            Add-AzureADGroupMember -ObjectId $mGroup -RefObjectId $uObj -ErrorAction Stop
        } catch {
            Write-Output "Could not added users to $($SelectedGroup.DisplayName) $($_)"
        }
    } else {
        Write-Output "User $($_) was NOT found."
    }
}