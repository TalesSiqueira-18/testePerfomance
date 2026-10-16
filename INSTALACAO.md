# Guia de Instalação e Execução do K6 (Sem Docker)

## Passo 1: Instalar o Go

1. Baixe o Go para Windows: https://go.dev/dl/
2. Execute o instalador
3. Verifique a instalação:
   ```powershell
   go version
   ```

## Passo 2: Compilar o K6 com extensão InfluxDB

Abra o PowerShell e execute:

```powershell
# Instalar xk6
go install go.k6.io/xk6/cmd/xk6@latest

# Adicionar Go bin ao PATH (se necessário)
$env:Path += ";$env:USERPROFILE\go\bin"

# Compilar K6 com extensão InfluxDB
xk6 build --with github.com/grafana/xk6-output-influxdb@latest --output k6.exe
```

## Passo 3: Configurar Variáveis de Ambiente

Crie um arquivo `.env` ou configure as variáveis no PowerShell:

```powershell
$env:K6_INFLUXDB_ADDR = "http://localhost:8086"
$env:K6_INFLUXDB_TOKEN = "seu_token_aqui"
$env:K6_INFLUXDB_ORGANIZATION = "sua_organizacao"
$env:K6_INFLUXDB_BUCKET = "k6_metrics"
$env:VUS = "5"
$env:DURATION = "1m"
```

## Passo 4: Executar o Teste

```powershell
.\k6.exe run --out xk6-influxdb k6_script.js
```

## Alternativa: Baixar K6 Pré-compilado (sem InfluxDB)

Se quiser testar sem compilar primeiro:

1. Baixe o K6: https://github.com/grafana/k6/releases
2. Extraia e adicione ao PATH
3. Execute (sem InfluxDB):
   ```powershell
   k6 run k6_script.js
   ```

