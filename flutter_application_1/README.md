# Hook — socorro e guincho veicular

Aplicativo Flutter com backend em PHP + MySQL. Tem dois tipos de usuário:

- **Cliente**: cadastra veículos, pede guincho informando o ponto de encontro e acompanha o socorrista no mapa.
- **Socorrista (motorista)**: fica online, recebe os chamados próximos, aceita um e segue a rota até o cliente, atualizando o status do atendimento.

### Tecnologias

| Camada | Tecnologia |
|---|---|
| App | Flutter / Dart (Android e Web) — `google_maps_flutter`, `geolocator`, `geocoding`, `http` |
| Backend | PHP 8.2 (XAMPP), um arquivo por endpoint em `backend/api/` |
| Banco | MySQL / MariaDB (`hook_db`) |
| Serviços | Google Maps, OSRM (rotas), Gmail SMTP via PHPMailer (códigos por e-mail) |

### Funcionalidades

- Cadastro com confirmação por e-mail, login e recuperação de senha
- Cliente: veículos, ponto de encontro pelo GPS ou mapa, endereços salvos, pedido de guincho, acompanhamento do socorrista em tempo real, histórico
- Socorrista: ficar online, lista de chamados por distância, aceite, rota até o cliente com status do atendimento, ganhos
- Perfil: meus dados, senha, forma de pagamento padrão, ajuda, exclusão de conta

> A explicação detalhada de cada tela, função e endpoint, e de como o app conversa com o backend, está no PDF **[flutter_application_1/docs/Hook_Documentacao_Tecnica.pdf](flutter_application_1/docs/Hook_Documentacao_Tecnica.pdf)**. Este README cobre só como executar o projeto.

---

## 1. O que instalar (Windows)

| Ferramenta | Para quê | Observação |
|---|---|---|
| [Git](https://git-scm.com/) | clonar o projeto | |
| [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) 3.x | compilar o app | o projeto usa Dart `^3.11`. Confira com `flutter doctor` |
| [Android Studio](https://developer.android.com/studio) | Android SDK + emulador | crie um emulador **API 34 ou 35, imagem "Google APIs"** (as imagens mais novas, de 16 KB, travam com GPS) |
| **JDK 21** | compilar o Android | o Java 25 que vem no Android Studio **não funciona** com o Gradle do projeto. Veja o passo 2 |
| [XAMPP](https://www.apachefriends.org/) | Apache + MySQL (backend) | PHP 8.2 |
| [Composer](https://getcomposer.org/) | biblioteca de e-mail (PHPMailer) | pode ser só o `composer.phar` |
| Chave do **Google Maps** | mapas no Android | criada no [Google Cloud](https://console.cloud.google.com/), com a API **Maps SDK for Android** ativada |

---

## 2. Java 21 para o Flutter

O Android Studio instala o Java 25, e o Gradle 8.14 usado aqui só aceita até o Java 24. Instale o 21 e aponte o Flutter para ele (só uma vez na máquina):

```powershell
winget install --id Microsoft.OpenJDK.21 -e
flutter config --jdk-dir="C:\Program Files\Microsoft\jdk-21.0.13.21-hotspot"
```

Confira a pasta exata do JDK em `C:\Program Files\Microsoft\` (o número da versão pode mudar). Depois feche e abra o VS Code / terminal.

---

## 3. Clonar o projeto no lugar certo

O app chama o backend em `http://localhost/flutter_application_1/backend/api` (no emulador Android, `http://10.0.2.2/...`, que é o `localhost` do PC). Então a pasta `flutter_application_1` **precisa estar acessível em `C:\xampp\htdocs\flutter_application_1`**.

A forma mais simples, sem manter duas cópias:

```powershell
cd C:\xampp\htdocs
git clone https://github.com/iamvenux/Hook.git
mklink /J C:\xampp\htdocs\flutter_application_1 C:\xampp\htdocs\Hook\flutter_application_1
```

O `mklink /J` cria um "atalho de pasta" (junction): o Apache enxerga `htdocs\flutter_application_1`, mas os arquivos ficam no repositório clonado. Assim o que você edita e commita é o mesmo que o servidor usa.

> Se preferir clonar em outro lugar (por exemplo no OneDrive), faça o `mklink /J` apontando para lá. Evite copiar a pasta para o `htdocs`: a cópia fica desatualizada em relação ao Git.

---

## 4. Banco de dados

1. Abra o **XAMPP Control Panel** e inicie **Apache** e **MySQL**.
2. Crie o banco e importe o script. Pelo terminal:

   ```powershell
   cd C:\xampp\htdocs\flutter_application_1
   C:\xampp\mysql\bin\mysql.exe -u root -e "CREATE DATABASE hook_db CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
   C:\xampp\mysql\bin\mysql.exe -u root --default-character-set=utf8mb4 hook_db < hook_db.sql
   ```

   Ou pelo phpMyAdmin (`http://localhost/phpmyadmin`): crie o banco `hook_db` e importe o arquivo `hook_db.sql`.

3. **Já tinha o banco de uma versão anterior?** Não importe de novo; rode só a migração, que adiciona a tabela de endereços e a coluna de forma de pagamento:

   ```powershell
   C:\xampp\mysql\bin\mysql.exe -u root hook_db < backend\migracoes\2026-11-11_perfil.sql
   ```

O script já cria dois usuários de teste (senha `123456` para os dois):

| E-mail | Tipo |
|---|---|
| `cliente@hook.com` | cliente |
| `motorista@hook.com` | motorista |

A conexão usa `root` sem senha (padrão do XAMPP). Se o seu MySQL tiver senha, ajuste `backend/conexao.php` e `backend/config/banco.php`.

---

## 5. Backend (PHP)

### 5.1 Instalar o PHPMailer

O cadastro e a recuperação de senha enviam um código por e-mail. Sem esta etapa, criar conta falha com *"Class PHPMailer not found"*.

```powershell
cd C:\xampp\htdocs\flutter_application_1\backend
composer install
```

Se aparecer *"The zip extension and unzip/7z commands are both missing"*, rode com a extensão zip ligada só para este comando:

```powershell
C:\xampp\php\php.exe -d extension=zip C:\caminho\para\composer.phar install
```

### 5.2 Configurar o e-mail

Edite `backend/config_email.php` com uma conta Gmail e uma **senha de app** (não é a senha normal da conta):

1. Na Conta Google, ative a **Verificação em duas etapas**.
2. Acesse `myaccount.google.com/apppasswords` e gere uma senha para "Hook" (16 letras).
3. Coloque em `password`, e o mesmo Gmail em `username` e `from_email`.

> **Não commite esse arquivo com a senha real.** Antes de commitar, confira com `git status` que `config_email.php` não está na lista.

### 5.3 Testar se o backend responde

Abra no navegador: `http://localhost/flutter_application_1/backend/api/listar_veiculos.php?usuario_id=1`
Deve voltar um JSON (`{"sucesso":true,...}`). Se der erro de banco, volte ao passo 4.

---

## 6. Chave do Google Maps

A chave **não fica no código**: cada pessoa coloca a sua em `android/local.properties` (arquivo ignorado pelo Git). Abra o arquivo (ele é criado pelo Flutter no primeiro build) e adicione no final:

```properties
MAPS_API_KEY=AIza...sua_chave...
```

O `android/app/build.gradle.kts` lê essa linha e injeta no `AndroidManifest.xml`. Sem a chave o app abre, mas os mapas ficam em branco.

---

## 7. Rodar o app

```powershell
cd C:\xampp\htdocs\flutter_application_1
flutter pub get
flutter run
```

- Com o emulador aberto, o `flutter run` instala e abre o app nele.
- Para testar no **Chrome** (sem Android): `flutter run -d chrome`. Mapas e GPS funcionam no navegador com a permissão de localização.
- **Celular físico**: o `10.0.2.2` só funciona no emulador. Troque a URL em `lib/services/api_service.dart` (`baseUrl`) pelo IP do seu PC na rede, ex.: `http://192.168.0.10/flutter_application_1/backend/api`, e libere a porta 80 no firewall.

Teclas úteis no terminal do `flutter run`: `r` recarrega a tela (hot reload), `R` reinicia o app, `q` encerra. **Mudanças no `AndroidManifest.xml`, no Gradle ou em plugins exigem parar (`q`) e rodar `flutter run` de novo.**

### Testando o fluxo completo

Use dois usuários ao mesmo tempo (por exemplo, o cliente no emulador e o motorista no Chrome):

1. **Cliente**: faça login, cadastre um veículo, confira o ponto de encontro e toque em "Solicitar Resgate".
2. **Motorista**: faça login, fique **Online**. O chamado aparece na lista; aceite.
3. O cliente vê o motorista no mapa; o motorista avança o status ("Cheguei ao local" → "Iniciar atendimento" → "Finalizar").
4. Ao finalizar, o atendimento entra em **Perfil > Ganhos e repasses** do motorista e no **Histórico** do cliente.

No emulador, a localização padrão é a Califórnia (sede do Google). Mude em **⋯ (Extended Controls) > Location** para um endereço próximo, para que as distâncias e rotas façam sentido.

---

## 8. Problemas comuns

| Sintoma | Causa / solução |
|---|---|
| `Gradle build failed due to Java/Gradle incompatibility` | Java 25 em uso. Faça o passo 2 |
| `Unknown database 'hook_db'` | Banco não criado. Passo 4 |
| `Class "PHPMailer\PHPMailer\PHPMailer" not found` ao criar conta | Falta `composer install`. Passo 5.1 |
| `SMTP Error: Could not authenticate` | Senha de app errada/revogada. Passo 5.2 |
| Mapa em branco, só o logo do Google | Chave ausente/errada em `local.properties`, ou "Maps SDK for Android" desativada. Depois de ajustar, pare o app e rode `flutter run` de novo (hot reload não reinstala) |
| `flutter_application_1 isn't responding` logo após aceitar a permissão de localização | Instabilidade do emulador com GPS. Toque em "Wait"; se repetir, use um emulador API 34/35 "Google APIs" |
| App mostra endereço na Califórnia | É a posição falsa do emulador. Troque em Extended Controls > Location |
| `Não foi possível conectar ao servidor` | Apache/MySQL desligados, ou o projeto não está em `htdocs\flutter_application_1` |
| Criei conta e o código não chegou | Veja o spam; o código vale 10 min e a tela tem "reenviar". Confira o passo 5.2 |

---

## 9. Estrutura do projeto

```
flutter_application_1/
├── lib/
│   ├── main.dart            inicialização e tema
│   ├── screens/             telas (auth/, cliente/, socorrista/, perfil/)
│   ├── controllers/         regras de negócio, entre as telas e os serviços
│   ├── services/            acesso externo: API PHP, GPS, rotas (OSRM)
│   ├── models/              classes de dados (ChamadoDisponivel, EnderecoSalvo...)
│   └── widgets/             componentes reutilizáveis
├── backend/
│   ├── api/                 um arquivo PHP por endpoint
│   ├── conexao.php          conexão MySQL (mysqli)
│   ├── config_email.php     SMTP (não commitar com senha)
│   ├── email_service.php    envio de e-mail e códigos
│   └── migracoes/           scripts SQL para bancos já existentes
├── hook_db.sql              script completo do banco
├── android/                 projeto Android (chave do Maps via local.properties)
└── docs/Hook_Documentacao_Tecnica.pdf   explicação detalhada de cada função e da comunicação com o backend
```

Regra de dependência no app: **tela → controller → service**. As telas nunca chamam `ApiService` direto.

---

## 10. Contribuindo

```powershell
git checkout -b minha-branch
# ... alterações ...
flutter analyze            # precisa terminar sem erros
git add -A
git status                 # confira: config_email.php e local.properties NÃO podem aparecer
git commit -m "Descrição curta do que mudou"
git push -u origin minha-branch
```

Se mexer no banco, atualize o `hook_db.sql` **e** crie um arquivo em `backend/migracoes/` com o `ALTER`/`CREATE` para quem já tem o banco.
