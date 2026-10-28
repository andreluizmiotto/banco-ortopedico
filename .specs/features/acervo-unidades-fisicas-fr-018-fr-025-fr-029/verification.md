# acervo-unidades-fisicas-fr-018-fr-025-fr-029 verification

**Verdict**: PASS
**Mutations**: 3 - probed C10 (limite de 64 caracteres), C3 (ordem de identificador nulo) e C16 (atualização idempotente); todas mortas após a correção
**Proofs**: `proofs.md` em `dbdd14f`
**Verifier**: independent sub-agent (author != verifier)

## Findings

| Finding | Evidence | Fix | Closed |
| --- | --- | --- | --- |
| A confirmação de cadastro não mostrava o tipo do equipamento | `admin-acervo-manager.tsx` renderizava apenas `Equipamento cadastrado como {situação}`; C9 era walk e não conferia o tipo | O formulário resolve o nome do tipo enviado e a confirmação passa a mostrar `Equipamento {tipo} cadastrado como {situação}` | `dbdd14f` - C9 |
| As provas SQL não aplicavam a migration, então mutações na migration não eram observáveis | `supabase test db` rodava contra o banco já carregado; mutação `> 64` -> `>= 64` sobrevivia | As provas passaram a usar `scripts/acervo-test-db.sh`, que faz `db reset --local --yes` quando o hash de migration/seed/teste muda e então roda `supabase test db` | `dbdd14f` - C10, C3, C16 |
| C10 não aceitava o limite de 64 caracteres | Só existia o caso de 65 rejeitado | Adicionada assertion que cria `repeat('x', 64)` e confere `char_length = 64`; o caso de 65 continua rejeitado | `dbdd14f` - C10 |
| C3 não isolava "identificador nulo por último" da ordem de tipo | A única unidade com código nulo era de outro tipo, então a primeira chave de ordenação já a colocava no fim | Adicionada unidade `SYN-AQ-CR` com código nulo e a expectativa passa a ser 001, 002, 007 (nulo), 003 | `dbdd14f` - C3 |
| C6 provava resultado vazio, não a negação prometida no plano | RPCs retornavam `200 []` para sessão sem `admin_banco` ativo | As RPCs de leitura e opções passaram a levantar `42501` quando não há entidade derivada da sessão; os testes usam `throws_ok(..., '42501', ...)` | `dbdd14f` - C6 |
| C12 não provava "sem unidade e sem auditoria" | A assertion contava identificadores que nunca eram enviados e não olhava a auditoria | O teste captura as contagens de unidades e auditoria da entidade antes das criações inválidas e confere que ambas permanecem iguais | `dbdd14f` - C12 |

## Probes run beyond the checks

- Limite de 64 caracteres: criação com 64 caracteres e com 68 que resultam em 64 após `btrim`; ambas aceitas, e duplicidade de 64 rejeitada com `P0003`.
- Acervo vazio: entidade ativa sem unidades devolve uma linha com `bank_name` e `unit_id` nulo; a camada Next converte para `units: []` e a tela vazia é alcançável.
- Sessão autenticada sem `admin_banco`: após a correção, as RPCs de leitura e opções respondem com `42501`, coerente com a superfície do plano.
- Sem automação de navegador. Layout a 360 px, contraste e submissão interativa continuam como conferência manual do desenvolvedor, conforme `AGENTS.md`; não foram declarados verificados por código.
