<#
.SYNOPSIS
    Summarises container images from a JSON list: kind, tags, size and age.
.DESCRIPTION
    Release tags have no hyphen (0.1.2); pipeline build tags do (abc1234-12).
    Exit codes: 0 = no stale images, 1 = at least one image older than -MaxAgeDays,
                2 = the input file could not be read or parsed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Path,

    [int]$MaxAgeDays = 14,

    [datetime]$Now = [datetime]::UtcNow
)

function Get-ImageKind {
    param([string[]]$Tags)
    if (-not $Tags -or $Tags.Count -eq 0) { return 'untagged' }
    if ($Tags | Where-Object { $_ -notmatch '-' }) { return 'release' }
    return 'build'
}

function ConvertTo-ImageSummary {
    param($Image, [datetime]$Now)
    $tags = @($Image.imageTags | Where-Object { $_ })
    $pushed = [datetime]::Parse($Image.imagePushedAt).ToUniversalTime()
    [pscustomobject]@{
        Kind    = Get-ImageKind -Tags $tags
        Tags    = if ($tags.Count -gt 0) { $tags -join ',' } else { '<untagged>' }
        SizeMB  = [math]::Round($Image.imageSizeInBytes / 1000000, 1)
        AgeDays = [int][math]::Floor(($Now.ToUniversalTime() - $pushed).TotalDays)
    }
}

try {
    $images = Get-Content -Raw -Path $Path -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
}
catch {
    Write-Error "Could not read '$Path': $($_.Exception.Message)"
    exit 2
}

$summaries = @($images | ForEach-Object { ConvertTo-ImageSummary -Image $_ -Now $Now })
$summaries | Sort-Object AgeDays | Format-Table -AutoSize | Out-String | Write-Host

$stale = @($summaries | Where-Object { $_.AgeDays -gt $MaxAgeDays })
if ($stale.Count -gt 0) {
    Write-Host "RESULT: $($stale.Count) image(s) older than $MaxAgeDays days: $(($stale.Tags) -join '; ')"
    exit 1
}
Write-Host "RESULT: $($summaries.Count) image(s), none older than $MaxAgeDays days"
exit 0
