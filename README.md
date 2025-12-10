# 🚛 Carreta Digital - App Frontend

Aplicativo multiplataforma **(Web PWA e Android)** para acompanhamento em tempo real dos **KPIs**, metas e presença geográfica do projeto Carreta Digital.

# 🛠 Tecnologias Utilizadas

**Frontend (Mobile & Web):**

* **Framework:** Flutter (Dart)

* **Mapas:** flutter_map (OpenStreetMap)

* **Conexão:** http

* **Design:** Material Design 3 (Google Fonts, Cores Personalizadas)

* **Hospedagem:** [Netlify.com](https://www.netlify.com/)

**Backend (API):**

* **Linguagem:** Python 3

* **Framework:** Flask

* **Banco de Dados:** Google Sheets (via gspread e pandas)

* **Hospedagem:** [Render.com](https://render.com/)

**⚠️ MAIS INFORMAÇÕES: ⚠️** Para mais informações sobre o backend do aplicativo, acesse o repositório [carretaDigital-mobile-backend](https://github.com/Lucas-Fiche/carretaDigital-mobile-backend)

# 🚀 Como Rodar o Projeto Localmente
**1. Configurando o Backend (API)**

**⚠️ MAIS INFORMAÇÕES: ⚠️** Para mais informações sobre o backend do aplicativo, acesse o repositório [carretaDigital-mobile-backend](https://github.com/Lucas-Fiche/carretaDigital-mobile-backend)

A API lê os dados da planilha do Google e os entrega formatados em JSON.

```
# 1. Entre na pasta (se estiver separado)
cd backend

# 2. Ative o ambiente virtual
# Windows:
venv\Scripts\activate
# Linux/Mac/WSL:
source .venv/bin/activate

# 3. Instale as dependências (se for a primeira vez)
pip install -r requirements.txt

# 4. Inicie o servidor
python app.py
```

> **Nota:** A API rodará em `http://127.0.0.1:5000`. Certifique-se de que o arquivo `credentials.json` (chave do Google Cloud) esteja na mesma pasta do `app.py`.

**2. Configurando o Frontend (Flutter)**

O aplicativo consome a API e exibe os gráficos.

```
# 1. Entre na pasta do Flutter
cd frontend

# 2. Baixe os pacotes necessários
flutter pub get
```
**Rodando a Aplicação:**

**Opção A - Windows Nativo (Powershell/CMD):** Se estiver rodando direto no Windows, o comando padrão abre o Chrome automaticamente:

```
# 3. Rode o aplicativo
# Para rodar no Navegador (Chrome):
flutter run -d chrome
```
**Opção B - Linux / WSL2 (Ambiente de Desenvolvimento):** Para evitar erros de conexão com o Chrome do Windows (erro "Missing extension byte"), usamos o modo servidor:

```
# 3. Rode o aplicativo
# Para rodar no Navegador:
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080
```

> **Como acessar:** Após rodar o comando, abra o navegador no Windows e digite manualmente: `http://localhost:8080`.

> **Dica:** Para atualizar a tela após mudar o código, aperte `R` (maiúsculo) no terminal para forçar o Hot Restart.

**Opção C - Emulador Android:** Certifique-se de ter o emulador aberto ou celular conectado via USB.

```
# Para rodar no Emulador Android:
flutter run
```

# 📦 Gerando Versões para Publicação

Aqui estão os comandos para gerar os arquivos finais para entregar aos usuários.

🌐 **Versão Web (Site / PWA)**
Para atualizar o site no Netlify ou Vercel.

1. Limpe caches antigos (recomendado):

```
flutter clean
flutter pub get
```

2. Gere o build de produção:

```
flutter build web --release
```
3. **Onde fica o arquivo?** A pasta gerada está em: `build/web.`

4. **Como publicar?** Arraste a pasta web inteira para o painel de deploy do [Netlify Drop](https://www.netlify.com/).

# 📱 Versão Android (APK)

Para gerar o aplicativo instalável para Android.

1. Gere o APK:

```
flutter build apk --release
```

2. **Onde fica o arquivo?** O arquivo estará em: `build/app/outputs/flutter-apk/app-release.apk`.

3. **Como instalar?** Envie o arquivo para o celular (WhatsApp/Drive), renomeie para `CarretaDigital.apk` e instale. É necessário **permitir** instalação de "Fontes Desconhecidas".

# 🎨 Personalização e Manutenção

**Atualizar Ícones do App**

Se você mudar a logo em `assets/images/logo.png`, rode este comando para atualizar os ícones do Android e iOS:

```
dart run flutter_launcher_icons
```

(Certifique-se de atualizar também os ícones da pasta `web/icons` manualmente para a versão Web).

**Adicionar Novos Estados no Mapa**

O mapa só mostra "bolinhas" nos estados cadastrados no Python. Se a Carreta for para um estado novo:

1. Abra `app.py`.

2. Procure o dicionário `COORDENADAS_ESTADOS`.

3. Adicione o nome do estado (em maiúsculo, sem acento) e as coordenadas Lat/Lng.

**Problemas Comuns**

* **Mapa travando o scroll:** O mapa está configurado como InteractiveFlag.none para não atrapalhar a rolagem da página.

* **Erro de "Missing Extension Byte" (WSL):** Ao rodar flutter run no WSL, se der erro de conexão com o Chrome, use: flutter run -d web-server e abra o link manualmente no navegador do Windows.

* **API Demorando (Cold Start):** O plano gratuito do Render "dorme" após 15 minutos. O primeiro acesso do dia pode levar ~50 segundos.

# 📝 Licença

Esta aplicação é de uso interno do **Projeto Carreta Digital** e foi desenvolvida por **Lucas Fiche**.