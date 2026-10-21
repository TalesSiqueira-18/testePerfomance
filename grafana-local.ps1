# Sobe InfluxDB + Grafana na sua máquina (sem Docker) — mesmo papel do workflow do GitHub, mas local.
# Uso:
#   powershell -ExecutionPolicy Bypass -File .\grafana-local.ps1            (inicia; na 1ª vez baixa ~200 MB)
#   powershell -ExecutionPolicy Bypass -File .\grafana-local.ps1 -Parar     (desliga)
# Grafana: http://127.0.0.1:3000  (usuário admin / senha admin123) — só acessível do seu computador.
param([switch]$Parar)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"   # deixa o download bem mais rápido no PowerShell 5.1
$raiz = $PSScriptRoot
$ferramentas = Join-Path $raiz "ferramentas"
$pidsArquivo = Join-Path $ferramentas "pids.txt"

$influxVersao = "1.8.10"
$influxUrl = "https://dl.influxdata.com/influxdb/releases/influxdb-${influxVersao}_windows_amd64.zip"
$grafanaVersao = "12.0.0"
$grafanaUrl = "https://dl.grafana.com/oss/release/grafana-${grafanaVersao}.windows-amd64.zip"

$grafanaUser = "admin"
$grafanaSenha = "admin123"
$authHeader = @{ Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${grafanaUser}:${grafanaSenha}")) }

function Parar-Servicos {
  if (Test-Path $pidsArquivo) {
    Get-Content $pidsArquivo | ForEach-Object {
      try { Stop-Process -Id ([int]$_) -Force -ErrorAction Stop } catch {}
    }
    Remove-Item $pidsArquivo -Force
  }
  Write-Host "InfluxDB e Grafana desligados." -ForegroundColor Yellow
}

if ($Parar) { Parar-Servicos; exit 0 }

function Baixar-Se-Preciso($nome, $url, $pasta) {
  # A instalação só conta como completa quando o arquivo-marcador ".instalado-<url>" existe
  $marcador = Join-Path $pasta (".instalado-" + (Split-Path $url -Leaf))
  if (-not (Test-Path $marcador)) {
    Write-Host "Baixando $nome (so na primeira vez)..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force $pasta | Out-Null
    $zip = Join-Path $ferramentas "$nome.zip"
    if (-not (Test-Path $zip)) { Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing }
    # tar (nativo do Windows 10+) extrai zip grande melhor que o Expand-Archive do PowerShell 5.1
    & tar.exe -xf $zip -C $pasta
    if ($LASTEXITCODE -ne 0) { throw "Falha ao extrair $nome" }
    New-Item -ItemType File $marcador | Out-Null
    Remove-Item $zip -Force
  }
}

function Esperar($nome, $url, $headers) {
  for ($i = 1; $i -le 180; $i++) {
    try {
      Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 2 -Headers $headers | Out-Null
      Write-Host "OK  $nome esta rodando" -ForegroundColor Green
      return
    } catch { Start-Sleep -Seconds 1 }
  }
  throw "$nome nao respondeu em 3 min"
}

# Se já estiver rodando, só avisa
$proxyPadrao = [System.Net.WebRequest]::DefaultWebProxy
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy
try {
  Invoke-WebRequest -Uri "http://127.0.0.1:3000/api/health" -UseBasicParsing -TimeoutSec 2 | Out-Null
  Write-Host "Grafana ja esta rodando em http://127.0.0.1:3000" -ForegroundColor Green
  exit 0
} catch {}

# Downloads primeiro (usam o proxy da rede, se houver)
[System.Net.WebRequest]::DefaultWebProxy = $proxyPadrao
$influxPasta = Join-Path $ferramentas "influxdb"
$grafanaPasta = Join-Path $ferramentas "grafana"
Baixar-Se-Preciso "influxdb" $influxUrl $influxPasta
Baixar-Se-Preciso "grafana" $grafanaUrl $grafanaPasta

# Daqui em diante só conexões locais: vai direto, sem tentar detectar proxy (isso travava o localhost)
[System.Net.WebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy

# 1) InfluxDB
$influxd = Get-ChildItem $influxPasta -Recurse -Filter "influxd.exe" | Select-Object -First 1
$influxDados = Join-Path $ferramentas "influxdb-dados"
$influxConf = Join-Path $ferramentas "influxdb.conf"
@"
reporting-disabled = true
[meta]
  dir = "$($influxDados -replace '\\','/')/meta"
[data]
  dir = "$($influxDados -replace '\\','/')/data"
  wal-dir = "$($influxDados -replace '\\','/')/wal"
[http]
  bind-address = "127.0.0.1:8086"
"@ | Set-Content -Path $influxConf -Encoding ASCII
$influxJaRodando = $false
try { Invoke-WebRequest -Uri "http://127.0.0.1:8086/ping" -UseBasicParsing -TimeoutSec 2 | Out-Null; $influxJaRodando = $true } catch {}
if ($influxJaRodando) {
  $pInfluxId = (Get-Process influxd | Select-Object -First 1).Id
  Write-Host "OK  InfluxDB ja estava rodando" -ForegroundColor Green
} else {
  Write-Host "Iniciando InfluxDB (na 1a vez pode levar 1-2 min)..." -ForegroundColor Cyan
  $pInfluxId = (Start-Process -FilePath $influxd.FullName -ArgumentList "-config `"$influxConf`"" -WindowStyle Hidden -PassThru).Id
  Esperar "InfluxDB" "http://127.0.0.1:8086/ping" @{}
}
Invoke-WebRequest -Uri "http://127.0.0.1:8086/query" -Method Post -UseBasicParsing `
  -Body @{ q = "CREATE DATABASE k6_metrics" } | Out-Null

# 2) Grafana
# Versões novas usam "grafana.exe server"; as antigas, "grafana-server.exe"
$grafanaExe = Get-ChildItem $grafanaPasta -Recurse -Filter "grafana.exe" | Where-Object { $_.Directory.Name -eq "bin" } | Select-Object -First 1
$grafanaArgs = "server"
if (-not $grafanaExe) {
  $grafanaExe = Get-ChildItem $grafanaPasta -Recurse -Filter "grafana-server.exe" | Select-Object -First 1
  $grafanaArgs = ""
}
$grafanaHome = Split-Path (Split-Path $grafanaExe.FullName)
$env:GF_SECURITY_ADMIN_USER = $grafanaUser
$env:GF_SECURITY_ADMIN_PASSWORD = $grafanaSenha
$env:GF_SERVER_HTTP_ADDR = "127.0.0.1"
$env:GF_ANALYTICS_REPORTING_ENABLED = "false"
$env:GF_ANALYTICS_CHECK_FOR_UPDATES = "false"
Write-Host "Iniciando Grafana (na 1a vez pode levar 1-2 min)..." -ForegroundColor Cyan
$pGrafana = Start-Process -FilePath $grafanaExe.FullName -ArgumentList "$grafanaArgs --homepath `"$grafanaHome`"" `
  -WorkingDirectory $grafanaHome -WindowStyle Hidden -PassThru
"$pInfluxId`n$($pGrafana.Id)" | Set-Content $pidsArquivo
Esperar "Grafana" "http://127.0.0.1:3000/api/health" @{}

# 3) Fonte de dados InfluxDB no Grafana (recria para garantir)
try { Invoke-RestMethod -Uri "http://127.0.0.1:3000/api/datasources/name/InfluxDB-K6" -Method Delete -Headers $authHeader | Out-Null } catch {}
$ds = @{
  name = "InfluxDB-K6"; type = "influxdb"; url = "http://127.0.0.1:8086"; access = "proxy"
  isDefault = $true; database = "k6_metrics"; jsonData = @{ httpMode = "POST" }
} | ConvertTo-Json -Depth 5
Invoke-RestMethod -Uri "http://127.0.0.1:3000/api/datasources" -Method Post -Headers $authHeader `
  -ContentType "application/json" -Body $ds | Out-Null
$dsUid = (Invoke-RestMethod -Uri "http://127.0.0.1:3000/api/datasources/name/InfluxDB-K6" -Headers $authHeader).uid
Write-Host "OK  Fonte de dados InfluxDB-K6 configurada" -ForegroundColor Green

# 4) Importa o mesmo dashboard usado no GitHub
$dashTexto = [IO.File]::ReadAllText((Join-Path $raiz "grafana-dashboard.json"), [Text.Encoding]::UTF8)
$dashTexto = $dashTexto.Replace('${DS_INFLUXDB_K6}', $dsUid).Replace('${DataSource}', $dsUid)
$corpo = "{`"dashboard`": $dashTexto, `"overwrite`": true}"
$resp = Invoke-RestMethod -Uri "http://127.0.0.1:3000/api/dashboards/db" -Method Post -Headers $authHeader `
  -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($corpo))
$dashUrl = "http://127.0.0.1:3000$($resp.url)?refresh=5s"
Write-Host "OK  Dashboard importado" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Grafana pronto: $dashUrl" -ForegroundColor Cyan
Write-Host " Usuario: $grafanaUser   Senha: $grafanaSenha" -ForegroundColor Cyan
Write-Host " Agora rode o teste em outro terminal (rodar-ensaio.ps1)." -ForegroundColor Cyan
Write-Host " Para desligar: powershell -ExecutionPolicy Bypass -File .\grafana-local.ps1 -Parar" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Start-Process $dashUrl
