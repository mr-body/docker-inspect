# docker-inspect

Docker Inspect é uma ferramenta que permite inspecionar e interagir com o ambiente Docker através de uma API HTTP e uma interface web amigável. O projeto é organizado em dois serviços separados (API e UI) empacotados e orquestrados via Docker Compose.

---
![Screenshot](./.github/assets/Screenshot%20from%202026-06-19%2018-30-18.png)
---

## Features / Funcionalidades

- Lista e inspeciona recursos Docker:
  - Imagens, containers, redes e volumes
- Ações sobre recursos:
  - Remover imagens/networks, rodar novas imagens (`docker run`), conectar/desconectar containers em redes
- Execução de comandos e terminal remoto (endpoints para `command` / `terminal`)
- Autenticação básica via middleware (OpenAPI com Bearer/JWT configurado)
- UI web (Next.js + TypeScript) que consome a API para visualização e ações
- Exposição de documentação OpenAPI/Swagger via FastAPI (API)

---

## Arquitetura e serviços

- Repositório raiz contém:
  - `.gitmodules` apontando para os submódulos:
    - `docker-inspect-api` — API (FastAPI, Python)
    - `docker-inspect-ui` — UI (Next.js, TypeScript)
  - `docker-compose.yaml` — orquestra os dois serviços em uma mesma stack
- Serviços (conforme docker-compose):
  - `docker-inspect-api`
    - Build: `./docker-inspect-api`
    - Porta: `8000` (host:container = `8000:8000`)
    - Monta `/var/run/docker.sock` (acesso ao daemon Docker do host)
    - Variáveis de ambiente configuráveis: `ADMIN_USER`, `ADMIN_PASSWORD`
    - Stack: Python, FastAPI, uvicorn, execução de comandos Docker via subprocess
    - Serve também arquivos estáticos em `/ui` quando aplicável
  - `docker-inspect-ui`
    - Build: `./docker-inspect-ui`
    - Porta: `3000` (no container), mapeada para `3001` no host (`3001:3000`)
    - Stack: Next.js (TypeScript)
    - Configurada para apontar para a API (variáveis `SERVER`, `WS_SERVER` no compose)

---

## Tech stack resumido

- Backend/API: Python, FastAPI, uvicorn
- Frontend/UI: Next.js, TypeScript
- Orquestração local: Docker Compose
- Comunicação com Docker: usa a CLI `docker` via subprocess / acesso ao socket `/var/run/docker.sock`

---

## Requisitos (locais)

- Docker e Docker Compose instalados
- Git
- Acesso ao socket do Docker (`/var/run/docker.sock`) para a API funcionar corretamente
- Se for clonar via SSH: uma chave SSH com permissões. Os submódulos estão configurados por SSH no `.gitmodules`.

---

## Como baixar (com submódulos)

1. Clonar com submódulos (SSH, se tiver chave):
    ```bash
   git clone --recurse-submodules git@github.com:mr-body/docker-inspect.git
    ```
3. Ou, se já clonou sem submódulos:
    ```bash
   git submodule update --init --recursive
    ```

Observação sobre HTTPS vs SSH:
- As entradas em `.gitmodules` estão com URL SSH. Se preferir clonar via HTTPS ou usar CI sem chaves SSH, depois de clonar você pode alterar a URL do submodule para HTTPS:
  - git config submodule.docker-inspect-api.url https://github.com/mr-body/docker-inspect-api.git
  - git config submodule.docker-inspect-ui.url https://github.com/mr-body/docker-inspect-ui.git
  - git submodule sync
  - git submodule update --init --recursive

---

## Execução (modo recomendado: Docker Compose)

No diretório raiz do repositório:

1. Inicialize submódulos (se ainda não fez):
  ```bash
git submodule update --init --recursive
```

2. Subir a stack:
```bash
docker compose up --build
```

4. Acessos:
   - UI: http://localhost:3001 (conforme docker-compose)
   - API: http://localhost:8000
   - Health: http://localhost:8000/health
   - Swagger/OpenAPI (FastAPI): normalmente em `http://localhost:8000/docs` (ou `http://localhost:8000/redoc`)

---

## Executar separadamente (desenvolvimento)

Executar apenas a API localmente (sem Docker):

1. Entrar na pasta do submódulo da API:
   ```bash
   cd docker-inspect-api
   ```
2. Criar e ativar um ambiente virtual:
   ```bash
   python -m venv .venv
   ```
    ```bash
    source .venv/bin/activate  # (Linux/macOS) ou .venv\Scripts\activate (Windows)
    ```
3. Instalar dependências:
   ```bash
   pip install -r requirements.txt
   ```
4. Iniciar o servidor:
    ```bash
    uvicorn main:app --host 0.0.0.0 --port 8000 --reload
    ```

Executar apenas a UI localmente (desenvolvimento):

1. Entrar no DIR
   ```bash
   cd docker-inspect-ui
   ```
3. Instalar dependências:
   ```bash
   npm install
   ```
4. Rodar em dev:
   ```bash
   npm run dev
   ```
5. Ou buildar/rodar produção:
   ```bash
   npm run build
   ```
   ```bash
   npm start
   ```

Nota: ao rodar localmente sem Docker, a API ainda precisa acesso ao Docker (via socket) para executar comandos Docker, a menos que você stub/mocque as chamadas.

---

## Variáveis de ambiente (exemplos)

Exemplo `.env` (para uso com docker-compose ou substituição manual):

ADMIN_USER=admin
ADMIN_PASSWORD=admin
SERVER=http://localhost:8000
WS_SERVER=ws://localhost:8000

Recomenda-se NÃO usar credenciais default em produção. Use secrets do Docker ou sistemas de secret management.

---

## Endpoints de exemplo (API)

- GET /health
  - Retorna: { "status": "ok" }
- GET /image/
  - Lista imagens Docker
- POST /image/run
  - Body JSON: { "image": "nginx", "name": "meu-nginx", "ports": "8080:80", "volumes": "/host/path:/container/path" }
- DELETE /image/{image_id}
  - Remove imagem
- GET /network/
  - Lista redes
- POST /network/{id}/connect
  - Conecta um container a uma rede

Exemplo curl:
- Listar imagens:
  - curl http://localhost:8000/image/
- Rodar imagem:
  - curl -X POST http://localhost:8000/image/run -H "Content-Type: application/json" -d '{"image":"nginx","ports":"8080:80","name":"meu-nginx"}'

---

## Segurança e riscos importantes

- Montar `/var/run/docker.sock` dentro do container dá controle total do Docker do host — risco crítico. Não exponha isso em ambientes públicos nem em hosts não confiáveis.
- A API executa comandos via subprocess com argumentos vindos de requisições; é necessário validar e sanitizar entradas para evitar injeção de comandos.
- Credenciais padrão (`admin/admin` no docker-compose) são inseguras — altere antes de uso.
- CORS está atualmente configurado como permissivo (`allow_origins=["*"]`) — restrinja em produção.
- Submódulos via SSH podem falhar em CI; ajuste para HTTPS ou configure chaves.

---

## Boas práticas / recomendações

- Usar um proxy ou API gateway que limite comandos permitidos ou aplicar uma camada de autorização/role-based access control.
- Evitar expor o socket do Docker diretamente; se necessário, documentar este risco e proteger o host.
- Adicionar testes automatizados e CI (lint, security checks).
- Documentar endpoints sensíveis e adicionar rate-limiting / logging de auditoria.

---

## Troubleshooting

- Erro ao clonar submódulos (permissão SSH): use HTTPS ou configure sua chave SSH.
- API retornando erro ao executar `docker` comandos: verifique se o container/host tem Docker disponível e se o socket está montado corretamente.
- UI não conecta à API: verifique variáveis `SERVER`/`WS_SERVER` e CORS.

---

## Contribuição

Contribuições são bem-vindas. Sugestões:
- Melhorar validação de entradas para evitar injeção
- Adicionar testes e workflows de CI
- Melhorar instruções de segurança e deployment
- Implementar autenticação/authorization mais robusta

---

## Licença

Projeto licenciado sob Apache License 2.0 (veja o arquivo LICENSE).
