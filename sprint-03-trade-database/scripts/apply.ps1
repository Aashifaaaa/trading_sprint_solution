$ErrorActionPreference = 'Stop'
$SprintDir = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$RepoRoot = (Resolve-Path (Join-Path $SprintDir '..')).Path
$EnvFile = Join-Path $RepoRoot '.env'
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
            $parts = $line.Split('=', 2); $name=$parts[0].Trim(); $value=$parts[1].Trim()
            if ($value.StartsWith('"') -and $value.EndsWith('"')) { $value=$value.Substring(1,$value.Length-2) }
            [Environment]::SetEnvironmentVariable($name,$value,'Process')
        }
    }
}
$dbName=if($env:TARGET_DATABASE){$env:TARGET_DATABASE}elseif($env:POSTGRES_DB){$env:POSTGRES_DB}else{'trading'}
$dbHost=if($env:POSTGRES_HOST){$env:POSTGRES_HOST}else{'localhost'}
$dbPort=if($env:POSTGRES_PORT){$env:POSTGRES_PORT}else{'5432'}
$dbUser=if($env:POSTGRES_USER){$env:POSTGRES_USER}else{'postgres'}
$env:PGPASSWORD=if($env:POSTGRES_PASSWORD){$env:POSTGRES_PASSWORD}else{''}
if(-not(Get-Command psql -ErrorAction SilentlyContinue)){throw 'psql was not found. Install PostgreSQL 16 and add its bin directory to PATH.'}
Write-Host "Applying Sprint 3 migrations to $dbName at ${dbHost}:$dbPort..."
Get-ChildItem (Join-Path $SprintDir 'migrations') -Filter '*.sql' | Sort-Object Name | ForEach-Object {
    Write-Host "  -> $($_.Name)"; & psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -v ON_ERROR_STOP=1 -f $_.FullName
    if($LASTEXITCODE -ne 0){throw "Migration failed: $($_.Name)"}
}
Write-Host 'Loading seed files...'
Get-ChildItem (Join-Path $SprintDir 'seed') -Filter '*.sql' | Sort-Object Name | ForEach-Object {
    Write-Host "  -> $($_.Name)"; & psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -v ON_ERROR_STOP=1 -f $_.FullName
    if($LASTEXITCODE -ne 0){throw "Seed load failed: $($_.Name)"}
}
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Write-Host 'Sprint 3 database is migrated and seeded.'
