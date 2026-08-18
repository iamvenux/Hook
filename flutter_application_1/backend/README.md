# Hook — Backend (CodeIgniter 4 + MySQL)

Início da API. Cobre só autenticação por enquanto (registro/login de
cliente e motorista) — o restante (veículos, solicitações, avaliação)
já está mapeado nas rotas e nos models, faltando os controllers.

## 1. Criar o projeto CodeIgniter 4

No terminal, numa pasta separada do projeto Flutter:

```bash
composer create-project codeigniter4/appstarter hook-api
cd hook-api
```

## 2. Copiar os arquivos deste pacote pro projeto

Copie mantendo a mesma estrutura de pastas:

```
hook-api/
├── app/
│   ├── Controllers/Api/
│   │   ├── AuthController.php
│   │   └── BaseApiController.php
│   ├── Database/Migrations/
│   │   ├── 2026-08-17-100000_CreateUsuarios.php
│   │   ├── 2026-08-17-100100_CreateVeiculos.php
│   │   ├── 2026-08-17-100200_CreateSolicitacoes.php
│   │   └── 2026-08-17-100300_CreateAvaliacoes.php
│   ├── Filters/
│   │   └── TokenAuthFilter.php
│   └── Models/
│       ├── UsuarioModel.php
│       ├── VeiculoModel.php
│       ├── SolicitacaoModel.php
│       └── AvaliacaoModel.php
```

## 3. Configurar o `.env`

Copie `env` para `.env` (se ainda não existir) e preencha:

```
CI_ENVIRONMENT = development

app.baseURL = 'http://localhost:8080/'

database.default.hostname = localhost
database.default.database = hook_db
database.default.username = root
database.default.password = SUA_SENHA_AQUI
database.default.DBDriver = MySQLi
```

## 4. Criar o banco e as tabelas

Duas formas — escolha uma:

**A) Rodar as migrations (recomendado, fica versionado com o código):**
```bash
# primeiro crie o banco vazio:
mysql -u root -p -e "CREATE DATABASE hook_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# depois rode as migrations:
php spark migrate
```

**B) Ou importar o `schema.sql` direto:**
```bash
mysql -u root -p < schema.sql
```

## 5. Registrar o filtro de autenticação

Siga as instruções em `filtro_adicionar_em_Filters.php` — adicionar
`tokenAuth` no array `$aliases` de `app/Config/Filters.php`.

## 6. Adicionar as rotas

Cole o conteúdo de `rotas_adicionar_em_Routes.php` dentro do seu
`app/Config/Routes.php`.

## 7. Subir o servidor local

```bash
php spark serve
```

A API sobe em `http://localhost:8080`.

## 8. Testar

```bash
# Cadastrar um cliente
curl -X POST http://localhost:8080/api/auth/registro \
  -H "Content-Type: application/json" \
  -d '{"nome":"Livia Teste","email":"livia@teste.com","senha":"123456","tipo":"cliente"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"livia@teste.com","senha":"123456"}'
```

O login devolve um `token` — use ele nas próximas chamadas com o
header `Authorization: Bearer <token>`.

## O que falta (próximos passos do cronograma)

- Conectar o app Flutter nessas rotas (trocar os dados mockados das
  telas por chamadas HTTP reais — dá pra usar o pacote `http` que
  você já usa pra buscar rota no OSRM)
- Endpoint pra motorista atualizar `latitude_atual`/`longitude_atual`
  periodicamente (pro matching por proximidade funcionar com dado real)

## O que já está pronto

- `AuthController` — registro e login (cliente/motorista)
- `VeiculoController` — CRUD de veículos do cliente
- `SolicitacaoController` — criar pedido, consultar status (polling),
  histórico do cliente, cancelar, listar fila do motorista, aceitar
  (com proteção contra dois motoristas aceitando ao mesmo tempo),
  atualizar status (a_caminho/concluído/cancelado)
- `AvaliacaoController` — registrar nota (1 a 5) de uma solicitação concluída

## Sobre a conversão do backend do Felipe (Node.js)

A lógica de negócio (criar solicitação → motorista aceita com
proteção de concorrência → atualizar status → consultar por
polling) foi portada da versão em Node que o Felipe fez antes de
sair do grupo, adaptando pro escopo que vocês decidiram manter:

- **Sem Socket.io** — o app já vai fazer polling no
  `GET /api/solicitacoes/{id}` (é literalmente o mesmo endpoint que
  o Felipe tinha como fallback de consulta, só que aqui é o único
  caminho, não um extra)
- **Sem preço dinâmico por distância** — preço fixo por tipo de
  reboque (`SolicitacaoModel::PRECOS`), então não precisa de
  integração com Google Maps Distance Matrix pra cobrar
- **Sem comentário na avaliação, sem cartão de crédito/débito** —
  só nota de 1 a 5, só Pix/Dinheiro
- **Sem verificação de email/JWT** — token opaco simples, como já
  estava no início do back

⚠️ O zip original do Felipe (`App_Guincho-main`) tinha um `.env`
com chaves reais (API do Google Maps, JWT secret, credenciais de
e-mail). Se for reaproveitar qualquer coisa de lá pra além do que
já foi portado aqui, troque essas credenciais antes — não suba
esse `.env` pra nenhum repositório.

## Sobre a autenticação

Não usa JWT — é um token opaco (string aleatória) salvo em
`usuarios.api_token`, gerado no login e conferido pelo
`TokenAuthFilter` em toda rota protegida. Mais simples de explicar
na defesa e evita depender de lib externa via Composer só pra isso.
