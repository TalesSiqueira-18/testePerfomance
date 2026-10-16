# Teste de Performance com K6
## Solução de Load Testing Automatizada

*Performance Testing Platform*

---

## 📋 Objetivo do Projeto

Criar uma plataforma automatizada de testes de performance que:

- ✅ Execute testes de carga de forma automatizada
- ✅ Monitore métricas em tempo real
- ✅ Integre com CI/CD (GitHub Actions)
- ✅ Forneça dashboards visuais para análise
- ✅ Seja totalmente configurável via variáveis de ambiente

---

## 🏗️ Arquitetura da Solução

```
┌─────────────────┐
│   GitHub Actions│
│   (CI/CD)       │
└────────┬────────┘
         │
    ┌────▼────┐
    │   K6    │ ──► Testes de Performance
    └────┬────┘
         │
    ┌────▼────┐
    │ InfluxDB│ ──► Armazenamento de Métricas
    │   1.7   │
    └────┬────┘
         │
    ┌────▼────┐
    │ Grafana │ ──► Visualização e Dashboards
    └────┬────┘
         │
    ┌────▼────┐
    │  Ngrok  │ ──► Acesso Público (Tempo Real)
    └─────────┘
```

---

## 🛠️ Stack Tecnológico

### Ferramentas Principais

| Ferramenta | Versão | Função |
|------------|--------|--------|
| **K6** | v0.48+ | Framework de load testing |
| **InfluxDB** | 1.7 | Banco de dados time-series |
| **Grafana** | Latest | Visualização de métricas |
| **GitHub Actions** | - | CI/CD e automação |
| **Ngrok** | - | Túnel público para acesso |

### Linguagens e Formatos

- **JavaScript** - Scripts de teste K6
- **YAML** - Configuração CI/CD
- **Docker** - Containerização de serviços
- **InfluxQL** - Queries de métricas

---

## ✨ Funcionalidades Principais

### 1. Testes Configuráveis

- **Variáveis de Ambiente**: Totalmente parametrizável
- **Thresholds Dinâmicos**: Taxa de erro e latência configuráveis
- **Múltiplos Cenários**: Suporte a diferentes tipos de carga

### 2. Monitoramento em Tempo Real

- **Dashboard Grafana**: Visualização instantânea
- **Acesso Público**: Link ngrok para compartilhamento
- **Métricas Customizadas**: Error rate, response time, throughput

### 3. Integração CI/CD

- **Execução Automatizada**: Via GitHub Actions
- **Agendamento**: Testes periódicos (cron)
- **Trigger Manual**: Execução sob demanda

---

## 📊 Métricas Monitoradas

### Performance

- ✅ **Latência p95/p99**: Tempo de resposta percentil
- ✅ **Throughput**: Requisições por segundo
- ✅ **Taxa de Erro**: Percentual de falhas
- ✅ **Virtual Users**: Usuários simultâneos

### Thresholds Configuráveis

```javascript
MAX_ERROR_RATE: < 1% (configurável)
MAX_P95_LATENCY: < 500ms (configurável)
MIN_THROUGHPUT: > 0 req/s
```

---

## ⚙️ Configuração

### Variáveis de Ambiente Obrigatórias

```bash
# Teste
VUS=10                    # Usuários virtuais
DURATION=5m              # Duração do teste

# API
API_BASE_URL=https://api.exemplo.com
API_ENDPOINT=/v1/users

# Thresholds
MAX_ERROR_RATE=0.01      # 1% máximo de erro
MAX_P95_LATENCY=500      # 500ms máximo p95
```

### GitHub Variables

Configure no repositório:
- `K6_VUS`
- `K6_DURATION`
- `K6_API_BASE_URL`
- `K6_API_ENDPOINT`
- `K6_MAX_ERROR_RATE`
- `K6_MAX_P95_LATENCY`

---

## 🚀 Fluxo de Execução

### 1. Setup Automático

```
GitHub Actions inicia
    ↓
InfluxDB 1.7 (Docker)
    ↓
Grafana (Docker)
    ↓
Configuração de Datasource
    ↓
Importação de Dashboard
    ↓
Ngrok (Exposição Pública)
```

### 2. Execução do Teste

```
K6 executa testes
    ↓
Envia métricas → InfluxDB (tempo real)
    ↓
Grafana atualiza dashboard
    ↓
Acesso público via ngrok
```

### 3. Resultados

- ✅ Dados persistidos no InfluxDB
- ✅ Dashboard disponível por 30 minutos
- ✅ Relatório de thresholds (pass/fail)

---

## 📈 Dashboard Grafana

### Painéis Disponíveis

1. **Virtual Users**: Usuários ativos ao longo do tempo
2. **Requests per Second**: Throughput em tempo real
3. **Errors Per Second**: Taxa de erro
4. **Checks Per Second**: Validações de resposta
5. **Response Time**: Latência (mean, max, p90, p95)
6. **Heatmap**: Distribuição de latência

### Acesso

- **URL**: Fornecida via ngrok (pública)
- **Credenciais**: admin / admin123
- **Tempo Real**: Atualização automática durante o teste

---

## 🎯 Casos de Uso

### 1. Testes de API

- Validação de performance de endpoints
- Identificação de gargalos
- Testes de carga e stress

### 2. Monitoramento Contínuo

- Testes agendados (diários/semanais)
- Comparação de performance ao longo do tempo
- Alertas automáticos por thresholds

### 3. Validação de Deploy

- Testes pré-deploy
- Validação pós-deploy
- Comparação de versões

---

## 💡 Diferenciais

### ✅ Totalmente Automatizado

- Zero configuração manual
- Setup completo em minutos
- Infraestrutura efêmera (Docker)

### ✅ Acesso em Tempo Real

- Dashboard público via ngrok
- Visualização durante execução
- Compartilhamento fácil com equipe

### ✅ Configurável e Flexível

- 100% parametrizável
- Suporta múltiplas APIs
- Thresholds customizáveis

### ✅ Integração CI/CD Nativa

- GitHub Actions integrado
- Execução automática
- Histórico de execuções

---

## 📦 Estrutura do Projeto

```
k6/
├── k6_script.js              # Script principal de teste
├── .github/
│   └── workflows/
│       └── k6-performance-test.yml  # Pipeline CI/CD
├── grafana-dashboard.json    # Dashboard Grafana
├── env.example               # Exemplo de variáveis
└── README.md                 # Documentação
```

---

## 🔄 Próximos Passos

### Melhorias Futuras

1. **Múltiplos Cenários**
   - Ramp-up gradual
   - Spike testing
   - Soak testing

2. **Integrações**
   - Slack notifications
   - Email reports
   - Jira integration

3. **Métricas Avançadas**
   - Business metrics
   - Custom KPIs
   - Trend analysis

4. **Multi-Environment**
   - Dev, Staging, Prod
   - Comparação entre ambientes
   - Baseline tracking

---

## 📊 Resultados Esperados

### Benefícios

- ✅ **Detecção Precoce**: Identificar problemas antes do deploy
- ✅ **Qualidade**: Garantir SLA de performance
- ✅ **Visibilidade**: Dashboards para toda a equipe
- ✅ **Automação**: Redução de trabalho manual

### ROI

- ⏱️ **Tempo**: Testes automatizados em minutos
- 💰 **Custo**: Infraestrutura efêmera (sem custo fixo)
- 🎯 **Precisão**: Métricas objetivas e confiáveis

---

## 🤝 Conclusão

### Solução Completa de Performance Testing

- ✅ **Pronta para uso**: Setup automático
- ✅ **Escalável**: Suporta qualquer volume
- ✅ **Flexível**: Totalmente configurável
- ✅ **Integrada**: CI/CD nativo

### Próximos Passos

1. Configurar variáveis no GitHub
2. Executar primeiro teste
3. Acompanhar dashboard em tempo real
4. Analisar resultados e ajustar thresholds

---

## ❓ Perguntas?

**Contato**:  
📧 Equipe de Performance Testing  
🔗 Repositório: [GitHub]  
📚 Documentação: README.md

---

**Obrigado!**

*Performance Testing Platform*

