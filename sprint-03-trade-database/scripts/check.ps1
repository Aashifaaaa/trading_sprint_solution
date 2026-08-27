$ErrorActionPreference = 'Stop'
$SprintDir=(Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$RepoRoot=(Resolve-Path (Join-Path $SprintDir '..')).Path
$EnvFile=Join-Path $RepoRoot '.env'
if(Test-Path $EnvFile){Get-Content $EnvFile|ForEach-Object{$line=$_.Trim();if($line-and-not $line.StartsWith('#')-and $line.Contains('=')){$parts=$line.Split('=',2);$name=$parts[0].Trim();$value=$parts[1].Trim();if($value.StartsWith('"')-and $value.EndsWith('"')){$value=$value.Substring(1,$value.Length-2)};[Environment]::SetEnvironmentVariable($name,$value,'Process')}}}
$dbName=if($env:TARGET_DATABASE){$env:TARGET_DATABASE}elseif($env:POSTGRES_DB){$env:POSTGRES_DB}else{'trading'}
$dbHost=if($env:POSTGRES_HOST){$env:POSTGRES_HOST}else{'localhost'}
$dbPort=if($env:POSTGRES_PORT){$env:POSTGRES_PORT}else{'5432'}
$dbUser=if($env:POSTGRES_USER){$env:POSTGRES_USER}else{'postgres'}
$env:PGPASSWORD=if($env:POSTGRES_PASSWORD){$env:POSTGRES_PASSWORD}else{''}
if(-not(Get-Command psql -ErrorAction SilentlyContinue)){throw 'psql was not found in PATH.'}
function Invoke-Psql([string[]]$a){& psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -v ON_ERROR_STOP=1 -P pager=off @a;if($LASTEXITCODE-ne 0){throw 'psql command failed.'}}
Write-Host '== Tables ==';Invoke-Psql @('-c','\dt')
Write-Host '== Row counts ==';Invoke-Psql @('-c',"SELECT 'clients' AS table_name,count(*) FROM clients UNION ALL SELECT 'accounts',count(*) FROM accounts UNION ALL SELECT 'instruments',count(*) FROM instruments UNION ALL SELECT 'orders',count(*) FROM orders UNION ALL SELECT 'positions',count(*) FROM positions;")
Write-Host '== Account states ==';Invoke-Psql @('-c','SELECT status,count(*) FROM accounts GROUP BY status ORDER BY status;')
Write-Host '== Order states ==';Invoke-Psql @('-c','SELECT status,count(*) FROM orders GROUP BY status ORDER BY status;')
Write-Host '== Q1-Q6 ==';Invoke-Psql @('-f',(Join-Path $SprintDir 'design/queries.sql'))
Write-Host '== Duplicate idempotency probe: expected failure =='
$previousErrorActionPreference=$ErrorActionPreference
$ErrorActionPreference='Continue'
$dup=& psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -v ON_ERROR_STOP=1 -P pager=off -c "INSERT INTO orders (id,account_id,instrument_id,idempotency_key,side,quantity,price,status,placed_at,updated_on) VALUES ('ffffffff-ffff-4fff-8fff-ffffffffffff',1,101,'idem-0001','BUY',1,1.00,'NEW',now(),now());" 2>&1
$dupExitCode=$LASTEXITCODE
$dupText=$dup|Out-String
if($dupText-notmatch'duplicate key'){throw 'Duplicate idempotency constraint probe did not fail as expected.'};Write-Host $dupText
Write-Host '== Foreign key probe: expected failure =='
$fk=& psql -h $dbHost -p $dbPort -U $dbUser -d $dbName -v ON_ERROR_STOP=1 -P pager=off -c "INSERT INTO orders (id,account_id,instrument_id,idempotency_key,side,quantity,price,status,placed_at,updated_on) VALUES ('ffffffff-ffff-4fff-8fff-ffffffffffff',999999,101,'probe-fk-999','BUY',1,1.00,'NEW',now(),now());" 2>&1
$fkExitCode=$LASTEXITCODE
$fkText=$fk|Out-String
if($fkText-notmatch'foreign\s+key\s+constraint'){throw 'Foreign key constraint probe did not fail as expected.'};Write-Host $fkText
$ErrorActionPreference=$previousErrorActionPreference
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
Write-Host 'Sprint 3 checks completed.'
