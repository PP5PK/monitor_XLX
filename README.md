# 📡 monitor_XLX — Notificações Telegram para Refletor XLX

Bot de monitoramento em Bash para o serviço **xlxd**, que envia notificações automáticas via **Telegram** sempre que:

- Uma estação é **bloqueada pelo Gatekeeper** (tentativa de conexão ou transmissão não autorizada)
- Uma repetidora da **lista de monitoramento** se **conecta** ou **desconecta** do refletor

> Desenvolvido por **PP5KX** para uso na infraestrutura do refletor XLX300.

---

## ✨ Funcionalidades

- 🚫 **Alertas de bloqueio (Gatekeeper)** — detecta qualquer estação barrada pelo xlxd, com indicativo, IP, protocolo e tipo de ação (linking / transmitting)
- 🔗 **Conexão e desconexão** — monitora repetidoras específicas de uma lista configurável
- 🔕 **Anti-spam embutido** — suprime notificações duplicadas (janela de 30 s para transmissão, 15 s para linking)
- 🌐 **Link QRZ.com** — cada indicativo na mensagem é um hiperlink clicável direto para o perfil na QRZ
- 🃏 **Preview card opcional** — exibe um cartão com a prévia da página QRZ do indicativo diretamente na mensagem do Telegram
- 🕐 **Formatação de timestamp** — converte o formato syslog (`Mar 15 20:30:07`) para `DD/MM/AAAA HH:MM:SS`
- 📡 **Mapeamento de protocolos** — traduz o código numérico do xlxd para o nome legível (DExtra, DPlus, DCS, XLX Interlink, DMR+, DMR MMDVM, YSF, ICom G3, IMRS)
- 🐛 **Modo debug** — exibe no journal todas as linhas capturadas e os grupos extraídos pelas regex
- ⚙️ **Arquivo de configuração separado** — todos os parâmetros ajustáveis ficam em `monitor_XLX_data`, sem necessidade de editar o script principal
- 🔄 **Serviço systemd** — arquivo `.service` pronto, com dependência e reinício automático vinculados ao `xlxd.service`

---

## 📋 Pré-requisitos

| Requisito | Versão mínima |
|---|---|
| Sistema operacional | Linux com systemd |
| xlxd | Qualquer versão com journald |
| bash | 4.x ou superior |
| curl | Qualquer versão recente |

O script verifica a presença do `curl` na inicialização e interrompe com mensagem de erro caso não esteja instalado.

---

## 🤖 Criando o Bot no Telegram

Antes de configurar o serviço, você precisará de dois dados: o **token da API** do bot e o **ID do chat** de destino.

### 1. Obter o token via @BotFather

1. Abra o Telegram e pesquise por **@BotFather**
2. Inicie uma conversa e envie o comando `/newbot`
3. Siga as instruções: escolha um **nome de exibição** e um **username** (deve terminar em `bot`, ex: `xlx300_monitor_bot`)
4. Ao final, o BotFather enviará o token no formato:
   ```
   Use this token to access the HTTP API:
   123456789:AAFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```
5. Copie esse token — ele será o valor de `TELEGRAM_API` no arquivo de configuração

> ⚠️ Nunca compartilhe o token publicamente. Quem o tiver pode controlar o seu bot.

### 2. Obter o Chat ID via @userinfobot

O **Chat ID** identifica para onde o bot enviará as mensagens. Pode ser um chat privado com você ou um grupo.

**Para chat privado:**

1. Pesquise por **@userinfobot** no Telegram e inicie uma conversa
2. Envie qualquer mensagem (ex: `/start`)
3. O bot responderá com suas informações, incluindo o campo `Id:`:
   ```
   Id: 123456789
   ```

**Para um grupo:**

1. Adicione o **@userinfobot** ao grupo
2. Envie `/start@userinfobot` dentro do grupo
3. Ele responderá com o ID do grupo — um número **negativo** (ex: `-1001234567890`)
4. Após obter o ID, você pode remover o @userinfobot do grupo

> O bot criado via @BotFather também precisa ser **adicionado ao grupo** para poder enviar mensagens nele.

---

## ⚙️ Arquivo de configuração — `monitor_XLX_data`

Todas as opções ajustáveis estão centralizadas no arquivo `monitor_XLX_data`, instalado junto ao script em `/usr/local/bin/`. **Nunca é necessário editar o script principal.**

```bash
# Dados do bot Telegram
TELEGRAM_API="SEU_TOKEN_AQUI"
CHAT_ID="SEU_CHAT_ID_AQUI"

# Preview card do QRZ.com nas mensagens: 1 = ativado, 0 = desativado
ENABLE_PREVIEW=0

# Indicativos das repetidoras a monitorar (separados por |)
REPEATER_LIST="PP5CPI|PY2KES|PY4ALV|..."

# Debug do script: 1 = ativado, 0 = desativado
DEBUG=0
```

### Descrição dos parâmetros

| Parâmetro | Valores | Descrição |
|---|---|---|
| `TELEGRAM_API` | token string | Token do bot obtido via @BotFather |
| `CHAT_ID` | número inteiro | ID do chat ou grupo de destino (grupos têm valor negativo) |
| `ENABLE_PREVIEW` | `0` ou `1` | Controla a exibição do cartão de prévia da QRZ nas mensagens |
| `REPEATER_LIST` | indicativos separados por `\|` | Repetidoras monitoradas para eventos de conexão e desconexão |
| `DEBUG` | `0` ou `1` | Ativa log detalhado no journal para diagnóstico de erros |

### Sobre o `ENABLE_PREVIEW`

Este parâmetro controla como o link da QRZ.com aparece nas mensagens do Telegram:

- **`0` — Desativado:** o indicativo aparece como um simples hiperlink clicável no texto da mensagem
- **`1` — Ativado:** o Telegram exibe um **cartão de prévia** abaixo da mensagem com a imagem e os detalhes da página da estação na QRZ.com

> O preview pode aumentar o tamanho visual das mensagens em grupos movimentados. Recomenda-se `0` para grupos com alto volume de notificações.

---

## 🚀 Instalação

### 1. Clonar o repositório

```bash
git clone https://github.com/SEU_USUARIO/monitor_XLX.git
cd monitor_XLX
```

### 2. Editar o arquivo de configuração

Preencha o token e o chat ID obtidos nas etapas anteriores e ajuste as demais opções conforme necessário:

```bash
nano monitor_XLX_data
```

### 3. Copiar os arquivos

```bash
sudo cp monitor_XLX.sh /usr/local/bin/monitor_XLX.sh
sudo cp monitor_XLX_data /usr/local/bin/monitor_XLX_data
sudo chmod +x /usr/local/bin/monitor_XLX.sh
```

### 4. Instalar o serviço systemd

```bash
sudo cp monitor_XLX.service /etc/systemd/system/monitor_XLX.service
sudo systemctl daemon-reload
sudo systemctl enable --now monitor_XLX.service
```

> `enable --now` registra o serviço para iniciar automaticamente no boot **e** já o inicia imediatamente, dispensando um segundo comando.

### 5. Verificar o status

```bash
sudo systemctl status monitor_XLX.service
```

---

## 📩 Exemplos de mensagem

Todas as mensagens são enviadas com **HTML** e hiperlink clicável no indicativo.

**Bloqueio — tentativa de conexão:**
```
15/03/2025 20:30:07 - PY9XYZ, IP 177.x.x.x (DPlus) - Tentativa de conexão no XLX300
```

**Bloqueio — tentativa de transmissão:**
```
15/03/2025 20:30:07 - PY9XYZ/B, IP 177.x.x.x (YSF) - Tentativa de transmissão no XLX300
```

**Conexão de repetidora monitorada:**
```
15/03/2025 21:00:00 - A Repetidora PP5CPI, IP 200.x.x.x (DCS) - Conectou-se no XLX300-C
```

**Desconexão de repetidora monitorada:**
```
15/03/2025 22:45:00 - A Repetidora PP5CPI, IP 200.x.x.x (DCS) - Desconectou-se do XLX300-C
```

Com `ENABLE_PREVIEW=1`, cada mensagem exibe adicionalmente um cartão com a prévia da página QRZ do indicativo.

---

## 🗂 Estrutura do repositório

```
monitor_XLX/
├── monitor_XLX.sh          # Script principal (não editar)
├── monitor_XLX_data        # Arquivo de configuração do usuário
├── monitor_XLX.service     # Unit file do systemd
└── README.md
```

O script utiliza `/tmp/xlxd_last_events` como arquivo temporário para controle de eventos duplicados (rotação automática a cada 100 linhas).

---

## 🔄 Funcionamento interno

```
journalctl -u xlxd.service -f
        │
        ▼
┌───────────────────────┐
│   Linha do journal    │
└───────────┬───────────┘
            │
     ┌──────┴──────────────┐
     ▼                     ▼                    ▼
Gatekeeper?           Conexão?            Desconexão?
(qualquer             (REPEATER_          (REPEATER_
 indicativo)           LIST)               LIST)
     │                     │                    │
     ▼                     ▼                    ▼
Anti-spam             Formata             Formata
(15/30 s)             mensagem            mensagem
     │                     │                    │
     └──────────┬───────────┘                   │
                ▼                               │
   send_telegram_message(msg, indicativo) ◄─────┘
                │
                ▼
   ENABLE_PREVIEW=1 → cartão QRZ.com na mensagem
   ENABLE_PREVIEW=0 → somente link clicável no texto
```

O loop principal lê o journal em tempo real via `journalctl -f`. Cada linha é testada contra três expressões regulares na seguinte ordem:

1. `REGEX_GATEKEEPER` — bloqueios do Gatekeeper (qualquer indicativo)
2. `REGEX_CONNECT` — novos clientes presentes na `REPEATER_LIST`
3. `REGEX_DISCONNECT` — clientes removidos presentes na `REPEATER_LIST`

---

## 🛡 Serviço systemd

O arquivo `monitor_XLX.service` configura:

| Diretiva | Valor | Descrição |
|---|---|---|
| `After` | `xlxd.service` | Inicia somente após o xlxd |
| `BindsTo` | `xlxd.service` | Para junto com o xlxd |
| `Restart` | `always` | Reinicia automaticamente em caso de falha |
| `User` | `root` | Necessário para leitura do journal |

---

## 🐛 Debug

Para ativar o debug, edite o arquivo de configuração e altere o valor de `DEBUG`:

```bash
sudo nano /usr/local/bin/monitor_XLX_data
# Altere: DEBUG=1
sudo systemctl restart monitor_XLX.service
```

Para acompanhar a saída em tempo real:

```bash
sudo journalctl -u monitor_XLX.service -f
```

Com o debug ativo, cada linha capturada do journal e os grupos extraídos pelas regex são registrados no journal.

---

## 📜 Licença

Distribuído sob a licença **MIT**.  
Desenvolvido por [PP5KX](https://pp5kx.net) — Mafra, Santa Catarina, Brasil.
