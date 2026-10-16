import http from 'k6/http';
import { check } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');
let requestCounter = 0;

// Função para limpar strings de variáveis de ambiente (remove espaços, quebras de linha, etc)
function cleanEnvVar(value) {
  if (!value) {
    throw new Error('Variável de ambiente obrigatória não definida');
  }
  // Remove espaços, quebras de linha (\r\n, \n, \r) e caracteres de controle
  return value.trim().replace(/\r\n/g, '').replace(/\n/g, '').replace(/\r/g, '').trim();
}

// Lê e limpa variáveis de ambiente (todas obrigatórias)
const API_BASE_URL = cleanEnvVar(__ENV.API_BASE_URL);
const API_ENDPOINT = cleanEnvVar(__ENV.API_ENDPOINT);
const MAX_ERROR_RATE = parseFloat(cleanEnvVar(__ENV.MAX_ERROR_RATE));
const MAX_P95_LATENCY = parseInt(cleanEnvVar(__ENV.MAX_P95_LATENCY));
 
export const options = {
  scenarios: {
    load_test: {
      executor: 'constant-vus',
      vus: __ENV.VUS,
      duration: __ENV.DURATION,
    },
  },
  thresholds: {
    // Taxa de Erro: configurável via MAX_ERROR_RATE
    'http_req_failed': [`rate<${MAX_ERROR_RATE}`],
    'errors': [`rate<${MAX_ERROR_RATE}`],
      
    // Latência p95: configurável via MAX_P95_LATENCY
    'http_req_duration{expected_response:true}': [`p(95)<${MAX_P95_LATENCY}`],
    'response_time': [`p(95)<${MAX_P95_LATENCY}`],
    
    // Throughput: Monitorar tendência (sem threshold específico, apenas monitorar)
    'http_reqs': ['rate>0'],
  },
}; 
 
export default function () {
  requestCounter++;
  const currentRequest = requestCounter;
  
  // Monta URL completa garantindo formatação correta
  const baseUrl = API_BASE_URL.endsWith('/') ? API_BASE_URL.slice(0, -1) : API_BASE_URL;
  const endpoint = API_ENDPOINT.startsWith('/') ? API_ENDPOINT : `/${API_ENDPOINT}`;
  const url = `${baseUrl}${endpoint}`;

  const res = http.get(url, {
    tags: {
      name: `${url} - ${currentRequest}`,
      endpoint: API_ENDPOINT,
      request_number: currentRequest.toString(),
    },
  });

  const success = check(res, {
    'status is 200': (r) => r.status === 200,
  });

  errorRate.add(!success);
  responseTime.add(res.timings.duration);
}
