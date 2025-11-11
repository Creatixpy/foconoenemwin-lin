# Foco no ENEM – Desktop

Aplicativo desktop (Windows e Linux) do Foco no ENEM, conectado diretamente ao Supabase/Groq/Stripe/NewsAPI – sem depender das rotas Next.js. Nele o estudante consegue:

- Navegar pelo hub com métricas, CTAs para redação e simulados e destaques de notícias.
- Enviar redações para correção (tema sugerido, personalizado ou IA) e acompanhar os resultados em tempo real.
- Gerar simulados personalizados por disciplina, revisar desempenho e sincronizar o histórico.
- Acompanhar estatísticas, metas, conquistas e atividades recentes na conta.
- Ler notícias curadas, interagir na comunidade e apoiar via doação (Stripe Checkout).

## Requisitos

- Flutter 3.22+ com suporte a Windows/Linux.
- Supabase Project `wywcpbgipufylnaauewe` ativo (mesmo do site).
- Chaves de terceiros (Groq, Stripe, NewsAPI, RapidAPI/WorldTime) válidas.
- Variáveis de ambiente injetadas via `--dart-define`:

| Chave | Descrição |
| --- | --- |
| `SUPABASE_URL` | URL do projeto (`https://wywcpbgipufylnaauewe.supabase.co`). |
| `SUPABASE_ANON_KEY` | Chave anon do Supabase. |
| `SUPABASE_SERVICE_ROLE_KEY` | (Opcional) Service Role para rotinas admin e cron. |
| `API_BASE_URL` | Mantido para compatibilidade, pode apontar para `http://localhost`. |
| `GROQ_API_KEY` | Chave primária da Groq (correção, temas, questões). |
| `GROQ_MODEL` | Modelo principal (ex.: `llama-3.1-70b-versatile`). |
| `GROQ_FALLBACK_API_KEY` | (Opcional) chave secundária para fallback automático. |
| `GROQ_FALLBACK_MODEL` | Modelo usado com a chave de fallback. |
| `GROQ_MAX_ATTEMPTS` | Tentativas por provedor Groq (default `2`). |
| `WORLD_TIME_API_URL` | Endpoint que retorna a hora oficial de Brasília. |
| `NEWSAPI_API_KEY` | Usado para importar notícias educacionais. |
| `RAPIDAPI_KEY` | Fallback para sincronizar horário caso o endpoint público falhe. |
| `STRIPE_SECRET_KEY` | Chave para criar sessões de checkout de doação (Stripe). |
| `ADMIN_CRON_SECRET` | Segredo para rotinas administrativas/cron. |
| `ADMIN_ALLOWED_EMAILS` | Lista de e-mails com acesso às rotinas admin. |

Exemplo:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://wywcpbgipufylnaauewe.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... \
  --dart-define=GROQ_API_KEY=grq_xxx \
  --dart-define=GROQ_MODEL=llama-3.1-70b-versatile \
  --dart-define=WORLD_TIME_API_URL=https://worldtimeapi.org/api/timezone/America/Sao_Paulo \
  --dart-define=API_BASE_URL=http://localhost
```

Em produção use `.env` ou scripts para não expor as chaves diretamente.

## Estrutura

- `lib/app.dart` – tema global, roteamento declarativo (GoRouter) e Providers.
- `lib/bootstrap.dart` – inicialização do Supabase + ProviderScope.
- `lib/config` – `AppConfig` (env), constantes de layout e helpers.
- `lib/features` – módulos funcionais (auth, home, redação, questões, resultados, conta, notícias, comunidade, doação).
- `lib/core/services` – integrações Groq, rate limit, horário de funcionamento, analytics.
- `lib/features` – módulos funcionais (auth, home, redação, questões, resultados, conta, notícias, comunidade, doação) consumindo diretamente Supabase/Groq.

## Scripts úteis

```bash
# Windows
flutter build windows --dart-define-from-file=env.dev.json

# Linux
flutter build linux --dart-define-from-file=env.dev.json

# Testes
flutter test
```

Crie o arquivo `env.dev.json` inclinando os três `dart-define` necessários para evitar repetir comandos longos.

## Atualização automática via GitHub

- Defina `GITHUB_REPO` nos arquivos `env*.json` no formato `usuario/repositorio` (ex.: `gabriel/foco-no-enem-desktop`).
- Publique releases no GitHub contendo os instaladores para Windows/Linux; o app consulta periodicamente `https://github.com/<repo>/releases/latest`.
- Quando uma versão mais recente for encontrada, o app avisa o usuário e faz o download do instalador correspondente à plataforma.
- Para criar o repositório inicialmente:
  ```bash
  git init
  git remote add origin https://github.com/<usuario>/<repo>.git
  git add .
  git commit -m "chore: bootstrap"
  git push -u origin main
  ```
  Em seguida, crie um release com o binário mais recente para que o app possa comparar versões.
