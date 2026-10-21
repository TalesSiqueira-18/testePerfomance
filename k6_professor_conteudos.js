// Cenário: vários professores abrindo a tela "Conteúdos" do Novo LMS ao mesmo tempo.
// Todos os dados sensíveis (URL, chave, token, id) vêm de variáveis de ambiente —
// NUNCA escreva token ou URL de produção neste arquivo (o repositório é público).
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import encoding from 'k6/encoding';

function required(name) {
  const value = __ENV[name];
  if (!value) {
    throw new Error(`Variável de ambiente obrigatória não definida: ${name}`);
  }
  return value.trim();
}

const SUPABASE_URL = required('SUPABASE_URL').replace(/\/$/, '');
const APIKEY = required('APIKEY');
const TOKEN = required('TOKEN');
const USER_ID = required('USER_ID');
const TURMA = required('TURMA'); // ex.: 27M1A
const SERIE = required('SERIE'); // ex.: 1ª Série (exatamente como aparece no Payload do navegador)

// Carga pequena por padrão (ensaio diurno). Aumente só com autorização.
const VUS = parseInt(__ENV.VUS || '5');
const DURATION = __ENV.DURATION || '1m';

// TIPO=carga    → sobe até VUS, mantém por DURATION e desce (padrão)
// TIPO=ruptura  → sobe em degraus de DEGRAU professores a cada DURATION até VUS,
//                 e PARA SOZINHO quando o sistema quebra (só rodar à noite, com aviso)
const TIPO = (__ENV.TIPO || 'carga').trim();
const DEGRAU = parseInt(__ENV.DEGRAU || '25');

function estagiosCarga() {
  return [
    { duration: '30s', target: VUS }, // professores vão chegando
    { duration: DURATION, target: VUS }, // todos usando ao mesmo tempo
    { duration: '30s', target: 0 }, // vão saindo
  ];
}

function estagiosRuptura() {
  const estagios = [];
  for (let alvo = DEGRAU; alvo <= VUS; alvo += DEGRAU) {
    estagios.push({ duration: '15s', target: alvo }); // sobe para o próximo degrau
    estagios.push({ duration: DURATION, target: alvo }); // segura o degrau
  }
  return estagios;
}

const thresholdsCarga = {
  // Valores iniciais — combinar os limites oficiais com a Naty
  http_req_failed: ['rate<0.01'],
  http_req_duration: ['p(95)<2000'],
  checks: ['rate>0.99'],
};

// Freio automático: considera que "quebrou" com mais de 10% de erro ou p95 acima de 10 s
const thresholdsRuptura = {
  http_req_failed: [{ threshold: 'rate<0.10', abortOnFail: true, delayAbortEval: '30s' }],
  http_req_duration: [{ threshold: 'p(95)<10000', abortOnFail: true, delayAbortEval: '30s' }],
  checks: ['rate>0.90'],
};

export const options = {
  scenarios: {
    professores_abrindo_conteudos: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: TIPO === 'ruptura' ? estagiosRuptura() : estagiosCarga(),
    },
  },
  thresholds: TIPO === 'ruptura' ? thresholdsRuptura : thresholdsCarga,
};

// Cada tipo de chamada do Supabase usa headers um pouco diferentes
// Funções do banco: POST /rest/v1/rpc/<nome>
const headersRpc = {
  apikey: APIKEY,
  authorization: `Bearer ${TOKEN}`,
  'content-type': 'application/json',
  'content-profile': 'public',
};
// Consulta direta a tabela: GET /rest/v1/<tabela>?...
const headersTabela = {
  apikey: APIKEY,
  authorization: `Bearer ${TOKEN}`,
  'accept-profile': 'public',
};
// Edge Functions: POST /functions/v1/<nome> (o navegador não manda apikey)
const headersEdgeFunction = {
  authorization: `Bearer ${TOKEN}`,
  'content-type': 'application/json',
};

const STUDENT_PROFILES_COLUNAS = [
  'componente_curricular', 'serie_ano', 'turma', 'colecao', 'segmento', 'escola',
  'nome_aluno', 'email_aluno', 'periodo_letivo', 'matricula', 'perfil',
].join(',');

// Chamadas que o navegador faz ao abrir a tela Conteúdos.
// Para adicionar uma nova: copie um bloco e ajuste name, method, url, body e headers conforme o cURL.
function chamadasTelaConteudos() {
  return [
    {
      name: 'get_user_profile',
      method: 'POST',
      url: `${SUPABASE_URL}/rest/v1/rpc/get_user_profile`,
      body: JSON.stringify({ _user_id: USER_ID }),
      headers: headersRpc,
    },
    {
      name: 'docente_escopo',
      method: 'POST',
      url: `${SUPABASE_URL}/rest/v1/rpc/docente_escopo`,
      body: JSON.stringify({}),
      headers: headersRpc,
    },
    {
      name: 'docente_turma_colecoes',
      method: 'POST',
      url: `${SUPABASE_URL}/rest/v1/rpc/docente_turma_colecoes`,
      body: JSON.stringify({}),
      headers: headersRpc,
    },
    {
      name: 'docente_desempenho_alunos',
      method: 'POST',
      url: `${SUPABASE_URL}/rest/v1/rpc/docente_desempenho_alunos`,
      body: JSON.stringify({ p_segmento: null, p_componente: null, p_turma: null }),
      headers: headersRpc,
    },
    {
      name: 'docente_desempenho_capitulos',
      method: 'POST',
      url: `${SUPABASE_URL}/rest/v1/rpc/docente_desempenho_capitulos`,
      body: JSON.stringify({ p_segmento: null, p_componente: null, p_turma: TURMA, p_serie: SERIE }),
      headers: headersRpc,
    },
    {
      name: 'student_profiles',
      method: 'GET',
      url: `${SUPABASE_URL}/rest/v1/student_profiles?select=${encodeURIComponent(STUDENT_PROFILES_COLUNAS)}&user_id=eq.${USER_ID}`,
      body: null,
      headers: headersTabela,
    },
    {
      name: 'resolve-document (components)',
      method: 'POST',
      url: `${SUPABASE_URL}/functions/v1/resolve-document`,
      body: JSON.stringify({ action: 'list', level: 'components', sg_disciplinas: ['BIO', 'FIS', 'HIS', 'MAT'] }),
      headers: headersEdgeFunction,
    },
  ];
}

// Roda uma vez antes do teste: confere se o token ainda vale até o fim do teste.
export function setup() {
  let payload;
  try {
    payload = JSON.parse(encoding.b64decode(TOKEN.split('.')[1], 'rawurl', 's'));
  } catch (e) {
    throw new Error('Token inválido (incompleto ou colado errado) — copie o token de novo no navegador.');
  }
  const minutosRestantes = Math.floor((payload.exp * 1000 - Date.now()) / 60000);
  console.log(`Token expira em ${minutosRestantes} minuto(s).`);
  if (minutosRestantes < 5) {
    throw new Error('Token expirado ou quase expirando — faça login de novo e copie um token novo.');
  }

  // Uma chamada de teste antes de soltar a carga: se falhar, para tudo e mostra o motivo
  const teste = http.post(
    `${SUPABASE_URL}/rest/v1/rpc/get_user_profile`,
    JSON.stringify({ _user_id: USER_ID }),
    { headers: headersRpc, tags: { name: 'setup: teste do token' } }
  );
  if (teste.status !== 200) {
    throw new Error(
      `Chamada de teste falhou com status ${teste.status} — ` +
        `${teste.status === 401 ? 'token inválido: copie de novo (só o texto que começa com eyJ)' : 'veja a mensagem'}: ` +
        `${String(teste.body).slice(0, 200)}`
    );
  }
  console.log('Chamada de teste OK (status 200). Iniciando a carga.');
}

export default function () {
  group('Abrir tela Conteúdos', () => {
    // O navegador dispara as chamadas em paralelo, então usamos http.batch
    const chamadas = chamadasTelaConteudos();
    const respostas = http.batch(
      chamadas.map((c) => ({
        method: c.method,
        url: c.url,
        body: c.body,
        params: { headers: c.headers, tags: { name: c.name } },
      }))
    );

    respostas.forEach((res, i) => {
      check(res, {
        [`${chamadas[i].name}: status 200`]: (r) => r.status === 200,
      });
    });
  });

  // Tempo que o professor fica olhando a tela antes da próxima ação (3 a 8 s)
  sleep(3 + Math.random() * 5);
}
