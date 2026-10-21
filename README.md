# Banco Ortopédico

Aplicação web para consulta de equipamentos ortopédicos e gestão dos bancos
participantes. A documentação do produto fica em [`docs/README.md`](docs/README.md).

## Requisitos locais

- Node.js 22 ou posterior e npm.
- Docker Desktop ou outro Docker daemon em execução.

## Iniciar o projeto

1. Instale as dependências:

   ```bash
   npm ci
   ```

2. Inicie o Supabase local:

   ```bash
   npx supabase start
   ```

3. Consulte os valores locais:

   ```bash
   npx supabase status -o env
   ```

   Crie `.env.local` na raiz e copie os valores correspondentes:

   ```dotenv
   NEXT_PUBLIC_SUPABASE_URL=<API_URL>
   NEXT_PUBLIC_SUPABASE_ANON_KEY=<ANON_KEY>
   SUPABASE_SERVICE_ROLE_KEY=<SERVICE_ROLE_KEY>
   ```

   Use `API_URL`, `ANON_KEY` e `SERVICE_ROLE_KEY` exibidos pelo comando. A chave
   `SUPABASE_SERVICE_ROLE_KEY` é somente do servidor: não a prefixe com
   `NEXT_PUBLIC_` e nunca adicione `.env.local` ao Git. O arquivo já é ignorado.

4. Recrie o banco local para aplicar migrations e carregar `supabase/seed.sql`:

   ```bash
   npx supabase db reset --local
   ```

   **Atenção:** esse comando apaga os dados locais do Supabase antes de recriá-los.
   Ele não deve ser usado contra um projeto de produção.

5. Inicie a aplicação:

   ```bash
   npm run dev
   ```

6. Abra <http://localhost:3000> ou a entrada administrativa em
   <http://localhost:3000/admin/entrar>.

## Acesso administrativo local

Depois do reset local, a fixture sintética de `supabase/seed.sql` permite testar
`/admin/entrar` com:

- **E-mail:** `admin-rotary-boa-vista@banco-ortopedico.test`
- **Senha:** `Rotary-Local-Synthetic-2026!`

Essas credenciais são públicas e exclusivas para desenvolvimento local; nunca as
use em produção. Se você executou `db reset` antes de receber a correção do seed,
execute o passo 4 novamente para recriar a identidade com o `instance_id` esperado
por Supabase Auth.

Após a entrada válida, a aplicação redireciona para `/admin/contatos`. A rota está
protegida, mas seu conteúdo ainda não foi implementado; a tela e as operações de
contatos pertencem à task FR-017/AC-007.

## Validação permitida

Com o Supabase local em execução, use:

```bash
npm run build
npx supabase test db
```

As verificações visuais são manuais; não use automação de navegador.
