---
marp: true
theme: default
paginate: true
---

# 🚀 Teste de Performance com K6
## Plataforma Automatizada de Load Testing

Performance Testing Platform

---

## 📋 Visão Geral

**Objetivo**: Plataforma automatizada de testes de performance integrada ao CI/CD

**Stack**:
- K6 (Load Testing)
- InfluxDB 1.7 (Métricas)
- Grafana (Dashboards)
- GitHub Actions (CI/CD)
- Ngrok (Acesso Público)

---

## 🏗️ Arquitetura

```
GitHub Actions → K6 → InfluxDB → Grafana → Ngrok
     (CI/CD)   (Teste)  (Storage)  (Viz)   (Public)
```

**Fluxo**:
1. Workflow inicia serviços (Docker)
2. K6 executa testes
3. Métricas → InfluxDB (tempo real)
4. Grafana exibe dashboard
5. Ngrok expõe acesso público

---

## ✨ Funcionalidades

### ✅ Testes Configuráveis
- Variáveis de ambiente
- Thresholds dinâmicos
- Múltiplos cenários

### ✅ Monitoramento Tempo Real
- Dashboard Grafana
- Acesso público (ngrok)
- Métricas customizadas

### ✅ CI/CD Integrado
- Execução automática
- Agendamento (cron)
- Trigger manual

---

## 📊 Métricas Monitoradas

| Métrica | Descrição |
|---------|-----------|
| **Latência p95/p99** | Tempo de resposta percentil |
| **Throughput** | Requisições por segundo |
| **Taxa de Erro** | Percentual de falhas |
| **Virtual Users** | Usuários simultâneos |

**Thresholds Configuráveis**:
- `MAX_ERROR_RATE`: < 1%
- `MAX_P95_LATENCY`: < 500ms

---

## ⚙️ Configuração

### Variáveis Obrigatórias

```bash
VUS=10                          # Usuários virtuais
DURATION=5m                     # Duração
API_BASE_URL=https://api.com    # URL base
API_ENDPOINT=/v1/users          # Endpoint
MAX_ERROR_RATE=0.01             # 1% erro máximo
MAX_P95_LATENCY=500             # 500ms máximo
```

**GitHub Variables**: Configure no repositório

---

## 🚀 Execução

### 1. Setup Automático
- InfluxDB 1.7 (Docker)
- Grafana (Docker)
- Datasource configurado
- Dashboard importado
- Ngrok iniciado

### 2. Teste em Tempo Real
- K6 executa testes
- Métricas → InfluxDB
- Dashboard atualiza
- Acesso via ngrok

### 3. Resultados
- Dados persistidos
- Dashboard 30min
- Relatório thresholds

--- 

## 📈 Dashboard Grafana

**Painéis**:
- Virtual Users
- Requests per Second
- Errors Per Second
- Response Time (mean, max, p90, p95)
- Heatmap de latência

**Acesso**:
- URL: ngrok (pública)
- Login: admin / admin123
- Tempo real durante teste

---

## 💡 Diferenciais

| Característica | Benefício |
|----------------|-----------|
| **Automático** | Zero configuração manual |
| **Tempo Real** | Dashboard público via ngrok |
| **Configurável** | 100% parametrizável |
| **CI/CD** | Integração nativa GitHub |

---

## 🎯 Casos de Uso

1. **Testes de API**
   - Validação de performance
   - Identificação de gargalos
   - Load e stress testing

2. **Monitoramento Contínuo**
   - Testes agendados
   - Comparação temporal
   - Alertas automáticos

3. **Validação de Deploy**
   - Pré e pós-deploy
   - Comparação de versões

---

## 📦 Estrutura

```
k6/
├── k6_script.js              # Script de teste
├── .github/workflows/        # CI/CD
├── grafana-dashboard.json    # Dashboard
└── env.example               # Variáveis
```

---

## 🔄 Próximos Passos

- ✅ Múltiplos cenários (ramp-up, spike, soak)
- ✅ Notificações (Slack, Email)
- ✅ Métricas avançadas (KPIs, trends)
- ✅ Multi-ambiente (dev/staging/prod)

---

## 📊 Resultados

**Benefícios**:
- ⏱️ Testes em minutos
- 💰 Infraestrutura efêmera
- 🎯 Métricas objetivas
- ✅ Detecção precoce de problemas

**ROI**: Redução de trabalho manual + Qualidade garantida

---

## 🤝 Conclusão

**Solução Completa**:
- ✅ Pronta para uso
- ✅ Escalável
- ✅ Flexível
- ✅ Integrada

**Próximos Passos**:
1. Configurar variáveis
2. Executar primeiro teste
3. Acompanhar dashboard
4. Ajustar thresholds

---

## ❓ Perguntas?

**Contato**: Equipe de Performance Testing

**Obrigado!** 🚀

*Performance Testing Platform*

