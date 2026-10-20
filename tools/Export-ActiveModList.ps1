param(
    [Parameter(Mandatory = $true)]
    [string]$ModsFile,

    [Parameter(Mandatory = $true)]
    [string]$WorkshopRoot,

    [Parameter(Mandatory = $true)]
    [string]$LocalModsRoot,

    [Parameter(Mandatory = $true)]
    [string]$CsvOutput,

    [Parameter(Mandatory = $true)]
    [string]$MarkdownOutput
)

$ErrorActionPreference = 'Stop'

function Read-ModInfo {
    param([string]$Path)

    $data = [ordered]@{}
    foreach ($line in Get-Content -LiteralPath $Path -Encoding UTF8) {
        if ($line -match '^\s*([^#=]+?)\s*=\s*(.*?)\s*$') {
            $key = $matches[1].Trim()
            if (-not $data.Contains($key)) {
                $data[$key] = $matches[2].Trim()
            }
        }
    }
    return $data
}

function Add-IndexEntry {
    param(
        [hashtable]$Index,
        [string]$InfoPath,
        [string]$Source,
        [string]$WorkshopId = ''
    )

    $info = Read-ModInfo -Path $InfoPath
    $id = $info['id']
    if ([string]::IsNullOrWhiteSpace($id)) {
        return
    }

    if (-not $Index.ContainsKey($id)) {
        $Index[$id] = [pscustomobject]@{
            ModId       = $id
            Name        = $info['name']
            Version     = $info['modversion']
            Requires    = $info['require']
            Source      = $Source
            WorkshopId  = $WorkshopId
        }
    }
}

$index = @{}

# Local entries take priority because Partner patches intentionally override no
# Workshop package and should be identified as local work.
Get-ChildItem -LiteralPath $LocalModsRoot -Directory |
    Where-Object { $_.Name -notin @('_PartnerBackups', 'examplemod') } |
    ForEach-Object {
        $top = $_
        $preferred = Join-Path $top.FullName 'common\mod.info'
        if (Test-Path -LiteralPath $preferred) {
            $source = if ($top.Name -like 'Partner*') { 'Local Partner patch' } else { 'Local external mod' }
            Add-IndexEntry -Index $index -InfoPath $preferred -Source $source
        }
        else {
            $candidate = Get-ChildItem -LiteralPath $top.FullName -Filter mod.info -File -Recurse |
                Where-Object { $_.FullName -notmatch '\\(_PartnerBackups|build|backup|decompiled|retired|staging)\\' } |
                Select-Object -First 1
            if ($candidate) {
                $source = if ($top.Name -like 'Partner*') { 'Local Partner patch' } else { 'Local external mod' }
                Add-IndexEntry -Index $index -InfoPath $candidate.FullName -Source $source
            }
        }
    }

Get-ChildItem -LiteralPath $WorkshopRoot -Directory | ForEach-Object {
    $workshopId = $_.Name
    Get-ChildItem -LiteralPath $_.FullName -Filter mod.info -File -Recurse | ForEach-Object {
        Add-IndexEntry -Index $index -InfoPath $_.FullName -Source 'Steam Workshop' -WorkshopId $workshopId
    }
}

$activeIds = foreach ($line in Get-Content -LiteralPath $ModsFile -Encoding UTF8) {
    if ($line -match '^\s*mod\s*=\s*(.*?),\s*$') {
        $matches[1].Trim()
    }
}

$rows = for ($i = 0; $i -lt $activeIds.Count; $i++) {
    $id = $activeIds[$i]
    $meta = $index[$id]
    if ($meta) {
        [pscustomobject]@{
            LoadOrder   = $i + 1
            ModId       = $id
            Name        = if ($meta.Name) { $meta.Name } else { $id }
            Source      = $meta.Source
            WorkshopId  = $meta.WorkshopId
            Version     = $meta.Version
            Requires    = $meta.Requires
        }
    }
    else {
        [pscustomobject]@{
            LoadOrder   = $i + 1
            ModId       = $id
            Name        = $id
            Source      = 'Unresolved from installed metadata'
            WorkshopId  = ''
            Version     = ''
            Requires    = ''
        }
    }
}

$rows | Export-Csv -LiteralPath $CsvOutput -NoTypeInformation -Encoding UTF8

function Escape-MarkdownCell([string]$Value) {
    if ($null -eq $Value) { return '' }
    return ($Value -replace '\|', '\|') -replace "`r?`n", ' '
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# 현재 싱글 세이브 활성 모드 목록')
$lines.Add('')
$lines.Add('- 기준 세이브: `2026-10-17_07-34-08`')
$lines.Add('- 기준 파일 갱신 시각: `' + (Get-Item -LiteralPath $ModsFile).LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss') + '`')
$lines.Add('- 활성 Mod ID 수: **' + $rows.Count + '**')
$lines.Add('- 이 목록은 설치 상태의 스냅샷이며, 다른 세이브나 이후 변경을 자동 반영하지 않습니다.')
$lines.Add('')
$lines.Add('| 순서 | Mod ID | 표시 이름 | 출처 | Workshop | 버전 |')
$lines.Add('|---:|---|---|---|---|---|')
foreach ($row in $rows) {
    $workshop = if ($row.WorkshopId) { '[' + $row.WorkshopId + '](https://steamcommunity.com/sharedfiles/filedetails/?id=' + $row.WorkshopId + ')' } else { '' }
    $lines.Add('| ' + $row.LoadOrder + ' | `' + (Escape-MarkdownCell $row.ModId) + '` | ' + (Escape-MarkdownCell $row.Name) + ' | ' + (Escape-MarkdownCell $row.Source) + ' | ' + $workshop + ' | ' + (Escape-MarkdownCell $row.Version) + ' |')
}

$lines | Set-Content -LiteralPath $MarkdownOutput -Encoding UTF8

$resolved = @($rows | Where-Object { $_.Source -ne 'Unresolved from installed metadata' }).Count
$unresolved = $rows.Count - $resolved
Write-Output "ACTIVE_MODS=$($rows.Count)"
Write-Output "RESOLVED=$resolved"
Write-Output "UNRESOLVED=$unresolved"
