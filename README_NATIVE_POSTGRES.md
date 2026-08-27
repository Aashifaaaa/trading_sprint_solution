# Native PostgreSQL setup

## Verify PostgreSQL
```powershell
psql --version
```

## Create database
```powershell
createdb -U postgres trading
```
Or:
```powershell
psql -U postgres -c "CREATE DATABASE trading;"
```

## Configure `.env`
```env
POSTGRES_DB=trading
POSTGRES_USER=postgres
POSTGRES_PASSWORD=YOUR_POSTGRES_INSTALLATION_PASSWORD
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
```

## Test
```powershell
psql -h localhost -p 5432 -U postgres -d trading -c "SELECT current_database(), current_user;"
```

## Apply Sprint 3
```powershell
cd sprint-03-trade-database
powershell -ExecutionPolicy Bypass -File scripts/apply.ps1
powershell -ExecutionPolicy Bypass -File scripts/check.ps1
```

## Sprint 4
```powershell
cd ..
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install -e ".\sprint-04-analytics-etl[dev]"
.\.venv\Scripts\python.exe -m pytest ".\sprint-04-analytics-etl" -q
```

Sprint 4 transform tests use fixtures and do not need PostgreSQL, Docker or the network.
