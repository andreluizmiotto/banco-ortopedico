# Autenticacao e Autorizacao

## 1. Requisitos de autenticacao

- A Comunidade entra com CPF e senha, sem escolher manualmente o papel. O
  servidor valida e normaliza o CPF, localiza o telefone confirmado associado
  ao perfil e autentica pelo Supabase Auth usando `phone/password`.
- A entrada do administrador do banco e separada: `/admin/entrar` usa e-mail e
  senha do Supabase Auth, sem cadastro administrativo na aplicacao.
- Aceitar senhas com pelo menos oito caracteres e frases-senha; nao exigir
  apenas numeros nem combinacoes obrigatorias de tipos de caracteres.
- CPF pode ser digitado com ou sem pontuacao e deve ser normalizado antes da
  validacao.
- O cadastro da Comunidade confirma o telefone por codigo antes de provisionar
  o perfil e o papel `community`.
- Recuperacao de senha deve usar codigo de uso unico e nao depender do
  administrador no fluxo normal; esse fluxo ainda nao esta implementado.
- O codigo proposto tem seis digitos, validade de dez minutos, espera de 60
  segundos entre reenvios e limite de tres envios por hora. Os limites finais
  dependem do provedor e devem ser aplicados no servidor.
- Apos cinco tentativas de senha invalidas consecutivas, a entrada da
  Comunidade bloqueia temporariamente a origem por 15 minutos. A duracao esta
  implementada no servidor; os limites de envio e a confiabilidade da origem
  em producao ainda dependem da configuracao operacional.
- Sessao longa em celular e saida voluntaria sao requisitos de produto. A
  duracao de 90 dias nao e um valor aprovado; duracao e renovacao devem ser
  validadas na implementacao.

## 2. Fluxos decididos e implementados

### Comunidade — DECIDIDO E IMPLEMENTADO

O CPF e o identificador de negocio, nao uma credencial do Supabase Auth. Na
entrada, o servidor valida o CPF e usa a funcao privada
`public.community_phone_for_cpf(text)` para localizar o telefone confirmado do
perfil. Em seguida, autentica com o Supabase Auth usando `phone/password`. A
senha e validada e armazenada pelo Supabase Auth; o perfil privado liga-se a
`auth.users.id` e guarda o CPF normalizado com unicidade no banco.

No cadastro, a pessoa confirma o telefone por codigo. Depois da confirmacao, o
servidor provisiona o perfil, registra a versao e a data do aviso aceito e
concede o papel `community`. O fluxo nao pede endereco residencial e nao
permite escolher o papel na tela.

### Administrador do banco — DECIDIDO E IMPLEMENTADO

O administrador entra por `/admin/entrar` com e-mail e senha do Supabase Auth.
Essa rota e separada de `/entrar` e nao oferece cadastro administrativo. A
aplicacao deriva o acesso de `auth.uid()` e do vinculo ativo `bank_admin` no
banco; cada administrador tem um unico escopo de entidade.
A entrada autorizada encaminha para `/admin/contatos`.

Os dois fluxos delegam credenciais ao Supabase Auth e nao armazenam senha ou
hash de senha nas tabelas de perfil.

### Pendencias operacionais

Os fluxos de entrada estao decididos e implementados, mas isso nao fecha todos
os requisitos de autenticacao para producao. Ainda dependem de decisao ou
configuracao: provedor e limites de SMS, texto de privacidade aprovado,
provisionamento da identidade administrativa e senha inicial, recuperacao de
senha administrativa e duracao/renovacao da sessao administrativa.

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
