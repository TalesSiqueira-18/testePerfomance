# Script para baixar e configurar K6 pré-compilado

Write-Host "Baixando K6 pré-compilado..." -ForegroundColor Green

# URL da última versão do K6 para Windows
$k6Version = "v0.48.0"
$downloadUrl = "https://github.com/grafana/k6/releases/download/$k6Version/k6-$k6Version-windows-amd64.zip"
$zipFile = "k6.zip"

try {
    Write-Host "Baixando de: $downloadUrl" -ForegroundColor Yellow
    Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile -UseBasicParsing
    
    Write-Host "Extraindo arquivos..." -ForegroundColor Yellow
    Expand-Archive -Path $zipFile -DestinationPath . -Force
    Remove-Item $zipFile
    
    # Renomeia o executável
    $extractedFile = "k6-$k6Version-windows-amd64\k6.exe"
    if (Test-Path $extractedFile) {
        Copy-Item $extractedFile -Destination "k6.exe" -Force
        Remove-Item "k6-$k6Version-windows-amd64" -Recurse -Force
        Write-Host ""
        Write-Host "K6 instalado com sucesso!" -ForegroundColor Green
        Write-Host "Execute: .\k6.exe run k6_script.js" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "NOTA: Esta versão NÃO tem suporte ao InfluxDB." -ForegroundColor Yellow
        Write-Host "Para enviar ao InfluxDB, você precisa compilar com Go." -ForegroundColor Yellow
    } else {
        Write-Host "Erro: Arquivo não encontrado após extração" -ForegroundColor Red
    }
} catch {
    Write-Host "Erro ao baixar: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Baixe manualmente de: https://github.com/grafana/k6/releases" -ForegroundColor Yellow
}

