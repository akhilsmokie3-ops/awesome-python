<#
.SYNOPSIS
    Self-activate an Azure AD / Microsoft Entra PIM role via Microsoft Graph PowerShell.

.DESCRIPTION
    Complete script for Privileged Identity Management (PIM) role self-activation.
    Handles module installation, authentication (with MFA), dynamic role discovery,
    activation, status polling, and optional deactivation.

    Based on:
    https://learn.microsoft.com/en-us/graph/api/rbacapplication-post-roleassignmentschedulerequests

.NOTES
    Author  : Akhil (QIH³B)
    Version : 1.1.0
    Date    : 2026-04-12
    Requires: PowerShell 5.1+ or PowerShell 7+
              Microsoft.Graph.Identity.Governance module
#>

# ──────────────────────────────────────────────
# 0. CONFIGURATION — edit these values
# ──────────────────────────────────────────────

$Config = @{
    # Replace with your real UPN (e.g. akhil@contoso.onmicrosoft.com)
    UPN              = "akhilsmokie7@gmail.com"

    # Role to activate — default is Attribute Definition Administrator
    # To find other role IDs: Get-MgRoleManagementDirectoryRoleDefinition | Select DisplayName, Id
    RoleDefinitionId = "8424c6f0-a189-499e-bbd0-26c1753c96d4"

    # Scope — "/" means tenant-wide
    DirectoryScopeId = "/"

    # How long to keep the role active (ISO 8601 duration)
    Duration         = "PT5H"

    # Justification and ticket info for audit trail
    Justification    = "I need access to the Attribute Administrator role to manage attributes to be assigned to restricted AUs"
    TicketNumber     = "AKHIL-ATTR-0001"
    TicketSystem     = "QIH3B"

    # Polling config
    PollSeconds      = 10
    PollAttempts     = 12
}

# Graph scopes needed for PIM activation
$RequiredScopes = @(
    "User.ReadBasic.All",
    "RoleManagement.ReadWrite.Directory",
    "RoleAssignmentSchedule.ReadWrite.Directory",
    "RoleEligibilitySchedule.Read.Directory"
)

# ──────────────────────────────────────────────
# 1. INSTALL & IMPORT MODULES
# ──────────────────────────────────────────────

Write-Host "`n[1/6] Checking modules..." -ForegroundColor Cyan

$modules = @("Microsoft.Graph", "Microsoft.Graph.Identity.Governance")
foreach ($mod in $modules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Host "  Installing $mod..." -ForegroundColor Yellow
        Install-Module -Name $mod -Scope CurrentUser -Force -AllowClobber
    }
}

Import-Module Microsoft.Graph -ErrorAction Stop
Import-Module Microsoft.Graph.Identity.Governance -ErrorAction Stop
Write-Host "  Modules loaded." -ForegroundColor Green

# ──────────────────────────────────────────────
# 2. CONNECT TO MICROSOFT GRAPH (interactive, MFA-ready)
# ──────────────────────────────────────────────

Write-Host "`n[2/6] Connecting to Microsoft Graph..." -ForegroundColor Cyan

$ctx = Get-MgContext
if ($null -eq $ctx) {
    # Interactive login — browser will open for MFA
    Connect-MgGraph -Scopes $RequiredScopes
    $ctx = Get-MgContext
}

if ($null -eq $ctx) {
    Write-Error "Failed to connect to Microsoft Graph. Exiting."
    exit 1
}

Write-Host "  Connected as: $($ctx.Account)" -ForegroundColor Green
Write-Host "  Tenant:        $($ctx.TenantId)" -ForegroundColor Green
Write-Host "  Scopes:        $($ctx.Scopes -join ', ')" -ForegroundColor DarkGray

# ──────────────────────────────────────────────
# 3. RESOLVE PRINCIPAL ID
# ──────────────────────────────────────────────

Write-Host "`n[3/6] Resolving principalId..." -ForegroundColor Cyan

# Try by UPN first; fall back to OData filter if that fails
try {
    $user = Get-MgUser -UserId $Config.UPN -ErrorAction Stop
}
catch {
    Write-Host "  Direct lookup failed, trying OData filter..." -ForegroundColor Yellow
    $user = Get-MgUser -Filter "userPrincipalName eq '$($Config.UPN)'"
}

if ($null -eq $user -or [string]::IsNullOrEmpty($user.Id)) {
    Write-Error "Could not resolve user '$($Config.UPN)'. Check the UPN and try again."
    exit 1
}

$principalId = $user.Id
Write-Host "  User:          $($user.DisplayName)" -ForegroundColor Green
Write-Host "  PrincipalId:   $principalId" -ForegroundColor Green

# ──────────────────────────────────────────────
# 4. CHECK ELIGIBLE ROLES (optional but useful)
# ──────────────────────────────────────────────

Write-Host "`n[4/6] Checking eligible roles..." -ForegroundColor Cyan

try {
    $eligibleRoles = Get-MgRoleManagementDirectoryRoleEligibilitySchedule `
        -ExpandProperty RoleDefinition `
        -All `
        -Filter "principalId eq '$principalId'"

    if ($eligibleRoles.Count -eq 0) {
        Write-Warning "No eligible PIM roles found for this user."
        Write-Warning "The user must have an eligible (not active) assignment for the target role."
        exit 1
    }

    Write-Host "  Eligible roles:" -ForegroundColor Green
    foreach ($role in $eligibleRoles) {
        $mark = if ($role.RoleDefinition.Id -eq $Config.RoleDefinitionId) { " <-- TARGET" } else { "" }
        Write-Host "    - $($role.RoleDefinition.DisplayName) ($($role.RoleDefinition.Id))$mark"
    }

    # Verify target role is in the eligible list
    $targetEligible = $eligibleRoles | Where-Object { $_.RoleDefinition.Id -eq $Config.RoleDefinitionId }
    if ($null -eq $targetEligible) {
        Write-Warning "Target role '$($Config.RoleDefinitionId)' is NOT in your eligible roles."
        Write-Warning "You can only self-activate roles you are eligible for."
        exit 1
    }
}
catch {
    Write-Host "  Could not fetch eligible roles (non-fatal): $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  Proceeding with activation anyway..." -ForegroundColor Yellow
}

# ──────────────────────────────────────────────
# 5. ACTIVATE THE ROLE
# ──────────────────────────────────────────────

Write-Host "`n[5/6] Submitting self-activation request..." -ForegroundColor Cyan

$params = @{
    action           = "selfActivate"
    principalId      = $principalId
    roleDefinitionId = $Config.RoleDefinitionId
    directoryScopeId = $Config.DirectoryScopeId
    justification    = $Config.Justification
    scheduleInfo     = @{
        startDateTime = Get-Date
        expiration    = @{
            type     = "AfterDuration"
            duration = $Config.Duration
        }
    }
    ticketInfo       = @{
        ticketNumber = $Config.TicketNumber
        ticketSystem = $Config.TicketSystem
    }
}

Write-Host "  Action:        selfActivate" -ForegroundColor DarkGray
Write-Host "  Role:          $($Config.RoleDefinitionId)" -ForegroundColor DarkGray
Write-Host "  Duration:      $($Config.Duration)" -ForegroundColor DarkGray
Write-Host "  Justification: $($Config.Justification)" -ForegroundColor DarkGray
Write-Host "  Ticket:        $($Config.TicketNumber) / $($Config.TicketSystem)" -ForegroundColor DarkGray
Write-Host ""

try {
    $result = New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $params -ErrorAction Stop

    Write-Host "  Request submitted successfully." -ForegroundColor Green
    Write-Host ""
    Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║  ACTIVATION RESULT                       ║" -ForegroundColor Green
    Write-Host "  ╠══════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "  ║  Id:              $($result.Id)"
    Write-Host "  ║  Status:          $($result.Status)"
    Write-Host "  ║  Action:          $($result.Action)"
    Write-Host "  ║  RoleDefinition:  $($result.RoleDefinitionId)"
    Write-Host "  ║  PrincipalId:     $($result.PrincipalId)"
    Write-Host "  ║  Created:         $($result.CreatedDateTime)"
    Write-Host "  ║  Completed:       $($result.CompletedDateTime)"
    Write-Host "  ╚══════════════════════════════════════════╝"

    if ($result.Status -eq "Granted") {
        Write-Host "`n  Role activation GRANTED. You now have the role for $($Config.Duration)." -ForegroundColor Green
    }
    elseif ($result.Status -eq "PendingApproval") {
        Write-Host "`n  Role activation is PENDING APPROVAL. An admin must approve before it takes effect." -ForegroundColor Yellow
    }
    elseif ($result.Status -eq "PendingScheduleCreation") {
        Write-Host "`n  Role activation is being scheduled. Polling for final status..." -ForegroundColor Yellow
    }
    else {
        Write-Host "`n  Initial status: $($result.Status). Polling for latest state..." -ForegroundColor Yellow
    }
}
catch {
    $errorMsg = $_.Exception.Message

    Write-Host "  ACTIVATION FAILED" -ForegroundColor Red
    Write-Host "  Error: $errorMsg" -ForegroundColor Red
    Write-Host ""

    if ($errorMsg -match "MfaRule") {
        Write-Host "  FIX: Your PIM policy requires MFA. Make sure you:" -ForegroundColor Yellow
        Write-Host "    1. Used interactive login (Connect-MgGraph -Scopes ...)" -ForegroundColor Yellow
        Write-Host "    2. Completed the MFA challenge in the browser" -ForegroundColor Yellow
        Write-Host "    3. Are NOT using an app-only / device-code token" -ForegroundColor Yellow
        Write-Host "    4. Re-run Connect-MgGraph and then this script immediately after" -ForegroundColor Yellow
    }
    elseif ($errorMsg -match "RoleAssignmentExists") {
        Write-Host "  FIX: This role is already active. No action needed." -ForegroundColor Yellow
        Write-Host "    To check: Get-MgRoleManagementDirectoryRoleAssignmentScheduleInstance" -ForegroundColor Yellow
    }
    elseif ($errorMsg -match "SubjectNotFound|Request_ResourceNotFound") {
        Write-Host "  FIX: The principalId '$principalId' was not found." -ForegroundColor Yellow
        Write-Host "    Verify your UPN in the Config section." -ForegroundColor Yellow
    }
    elseif ($errorMsg -match "RoleAssignmentRequestNotFound|InvalidEligibleRoleAssignment") {
        Write-Host "  FIX: You are not eligible for this role in PIM." -ForegroundColor Yellow
        Write-Host "    Ask your admin to make you eligible, or check the role ID." -ForegroundColor Yellow
    }
    elseif ($errorMsg -match "Justification") {
        Write-Host "  FIX: Your policy likely requires a stronger justification." -ForegroundColor Yellow
        Write-Host "    Provide a longer business reason in `$Config.Justification." -ForegroundColor Yellow
    }

    exit 1
}

# ──────────────────────────────────────────────
# 6. POLL STATUS + OPTIONAL DEACTIVATION
# ──────────────────────────────────────────────

Write-Host "`n[6/6] Polling request status..." -ForegroundColor Cyan

$final = $result
for ($i = 1; $i -le [int]$Config.PollAttempts; $i++) {
    try {
        $current = Get-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -UnifiedRoleAssignmentScheduleRequestId $result.Id -ErrorAction Stop
        $final = $current
        Write-Host "  Attempt $i/$($Config.PollAttempts): $($current.Status)"

        if ($current.Status -in @("Granted", "Denied", "Canceled", "Failed")) {
            break
        }
    }
    catch {
        Write-Host "  Poll attempt $i failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    Start-Sleep -Seconds ([int]$Config.PollSeconds)
}

Write-Host "`n  Final status: $($final.Status)" -ForegroundColor Cyan
if ($final.Status -eq "Granted") {
    Write-Host "  ✅ Role is active." -ForegroundColor Green
}

$deactivate = Read-Host "`nDeactivate the role now? (y/N)"
if ($deactivate -match '^(y|yes)$') {
    try {
        $deactivationParams = @{
            action           = "selfDeactivate"
            principalId      = $principalId
            roleDefinitionId = $Config.RoleDefinitionId
            directoryScopeId = $Config.DirectoryScopeId
            justification    = "Deactivating after work completion"
        }

        $deactivateResult = New-MgRoleManagementDirectoryRoleAssignmentScheduleRequest -BodyParameter $deactivationParams -ErrorAction Stop
        Write-Host "  Deactivation request submitted. Status: $($deactivateResult.Status)" -ForegroundColor Green
    }
    catch {
        Write-Host "  Deactivation failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nDone." -ForegroundColor Green
