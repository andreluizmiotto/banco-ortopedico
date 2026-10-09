# Autenticacao e Autorizacao

## 1. Requisitos de autenticacao

- Entrada por CPF e senha, sem escolha manual de perfil.
- Aceitar senhas com pelo menos oito caracteres e frases-senha; nao exigir apenas numeros nem combinacoes obrigatorias de tipos de caracteres.
- CPF pode ser digitado com ou sem pontuacao e deve ser normalizado antes da validacao.
- O cadastro deve confirmar o telefone por codigo.
- Recuperacao de senha deve usar codigo de uso unico e nao depender do administrador no fluxo normal.
- O codigo proposto tem seis digitos, validade de dez minutos, espera de 60 segundos entre reenvios e limite de tres envios por hora. Os limites finais dependem do provedor e devem ser aplicados no servidor.
- Apos cinco tentativas de senha invalidas, aplicar bloqueio temporario e protecao contra abuso. A duracao de 15 minutos nao e decisao fechada; definir a politica no servidor sem criar um mecanismo facil de bloqueio malicioso de contas.
- Sessao longa em celular e saida voluntaria sao requisitos de produto. A duracao de 90 dias nao e um valor aprovado; duracao e renovacao devem ser validadas na implementacao.

## 2. Decisao de implementacao ainda necessaria

Supabase Auth gerencia credenciais e sessoes, mas CPF nao deve ser tratado automaticamente como um email inventado ou como uma senha. Antes de implementar, documentar e testar uma estrategia que:

- evite revelar se um CPF esta cadastrado;
- valide CPF no servidor e aplique rate limit;
- nao exponha CPF em URL, log, resposta de erro ou token legivel pelo cliente;
- mantenha a unicidade do CPF no banco;
- associe o perfil de negocio a `auth.users.id`;
- deixe o hash e a verificacao da senha exclusivamente com o Supabase Auth;
- permita operacao de recuperacao com codigo enviado ao telefone confirmado.

Nao criar autenticação paralela com senha ou hash mantidos na tabela de perfil.

## 3. Papeis

| Papel | Escopo de dados |
|---|---|
| Visitante | Catalogo e disponibilidade explicitamente publicos |
| Comunidade | Proprio perfil, proprios emprestimos e contatos permitidos |
| Companheiro | Catalogo e dados agregados; sem acesso a dados pessoais pelo proprio papel |
| Administrador do banco | Dados operacionais da entidade autorizada |
| Administrador geral | Operacoes globais autorizadas e auditoria |

Permissoes devem derivar de papeis ativos e vinculos de entidade verificados no servidor e no banco. Nao confiar em papel ou `entity_id` enviados pelo navegador.

## 4. Matriz de autorizacao

| Recurso | Publico | Comunidade | Companheiro | Admin banco | Admin geral |
|---|---:|---:|---:|---:|---:|
| Catalogo e disponibilidade agregada | Sim | Sim | Sim | Sim | Sim |
| Contato e enderecos | Nao | Sim | Nao pelo papel Companheiro | Sim | Sim |
| Proprio perfil e emprestimos | Nao | Sim | Nao pelo papel Companheiro | Sim | Sim |
| PII de outra pessoa | Nao | Nao | Nao | Campos minimos para operacao do proprio banco, sem historico externo | Escopo global auditado |
| Operar acervo | Nao | Nao | Nao | Somente propria entidade | Sim |
| Administrar entidades e papeis globais | Nao | Nao | Nao | Nao | Sim |

Admin de banco pode consultar disponibilidade agregada de outro banco, mas nao o historico nem a PII de pessoas atendidas por ele.

A busca por nome ou CPF so deve ocorrer dentro de um fluxo autorizado de emprestimo ou devolucao. Para iniciar um atendimento no proprio banco, o administrador pode receber os dados minimos necessarios da pessoa, mas nao o historico de outros bancos. Alertas cruzados dependem de aprovacao juridica e, se habilitados, retornam somente a sinalizacao generica aprovada, sem registros ou detalhes de outras entidades.

## 5. Regras RLS e servidor

- Habilitar RLS em tabelas com dados de usuario, emprestimo, equipamento, contato, modelo privado ou auditoria.
- Politicas devem derivar `auth.uid()` e papeis ativos de relacoes confiaveis no banco.
- Um admin de banco so pode ler e alterar linhas das entidades que administra.
- Companheiro deve consultar views ou funcoes que devolvam somente dados publicos e agregados; nunca dados pessoais, nome parcial, bairro ou registros individuais. Funcoes de autoatendimento para dados proprios devem exigir o papel Comunidade.
- O cliente nao deve receber colunas privadas para depois apenas oculta-las na interface.
- Operacoes globais devem passar por funcao/rota protegida e gravar auditoria.
- Atualizacoes de estoque e emprestimo devem ocorrer atomicamente e validar a situacao corrente.
- Testes negativos devem tentar acessar registro de outra entidade por ID conhecido.

## 6. Storage

- Buckets privados para termos, fotos assinadas, fotos de usuarios e documentos operacionais.
- Leitura por URL assinada de curta duracao, emitida apos autorizacao.
- Nunca incluir nome, CPF, telefone ou endereco no nome do bucket, objeto ou URL.
- Imagens publicas de equipamento devem passar por revisao de conteudo e metadados; remover EXIF quando puder revelar localizacao.
- Logo institucional so pode ser publico depois de autorizada a redistribuicao.

## 7. Acesso e desligamento

- Retirar um papel nao apaga a conta de comunidade nem historico que precisa ser mantido.
- Ao remover admin, revogar sessoes ou acessos relevantes e registrar ator, data e entidade.
- Alteracao de telefone exige nova verificacao.
- Troca manual de telefone por suporte deve registrar verificacao de identidade, ator, justificativa e data.
- Exclusao de conta deve seguir fluxo de retencao, emprestimos ativos e anonimizacao da politica de dados.
