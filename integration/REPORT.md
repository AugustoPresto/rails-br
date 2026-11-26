# Relatório: rails-br 0.2.1 em aplicações Rails reais

Executado em 26/11/2026 com a gem publicada no RubyGems. Como reproduzir: [README](README.md).

## Resumo

- A gem **funcionou em todas as combinações declaradas** de Ruby e Rails, sem falha em testes ou sob concorrência.
- Os testes revelaram **dois defeitos** que afetam sistemas reais, além de riscos de uso que precisam de código ou
  documentação.

## Matriz

| O quê | Execuções | Resultado |
|---|---|---|
| Apps Rails com PostgreSQL 15 | 16 combinações Ruby × Rails (2.7 a 3.4, 6.0 a 8.0) | todas passaram |
| Apps Rails com MySQL 8.0 | Ruby 2.7/Rails 6.0, 3.1/7.0 e 3.4/8.0 | todas passaram |
| Ruby sem Rails | 2.7, 3.0, 3.1, 3.2, 3.3 e 3.4 | todas passaram |

Cada app roda 15 testes (cerca de 40 mil asserções) e, em produção, com Puma e 16 threads, 3.200 requisições de
32 clientes simultâneos. Nas 19 execuções com Rails foram **60.800 requisições sem nenhuma resposta incorreta**.

## Carga com 1 milhão de registros (PostgreSQL)

Uma execução por combinação, numa única máquina (8 núcleos). Servem de ordem de grandeza.

| Operação (por segundo) | Ruby 2.7, Rails 6.0 | Ruby 3.4, Rails 8.0 |
|---|---|---|
| `insert_all` com `BigDecimal` e `Date`, sem a gem | 42.658 | 58.070 |
| `insert_all` com texto brasileiro, com a gem ¹ | 36.118 | 48.332 |
| `valid?` sem validadores | 107.756 | 192.981 |
| `valid?` com um validador de formato do Rails | 73.430 | 143.992 |
| `valid?` com os 5 validadores da gem ² | 16.359 | 41.189 |
| `CPF.valid?` isolado | 135.122 | 136.636 |
| `Currency.parse` isolado | 516.040 | 594.564 |
| Gerar e validar um BR Code | 5.060 | 15.255 |

- Nos pedidos gravados por texto, nenhum campo ficou nulo e a soma no banco conferiu com a calculada em Ruby.
- ¹ Cerca de 20% mais lento, incluindo no tempo a formatação das datas em texto feita pelo próprio teste.
- ² Na 3.4, cerca de 24 µs por registro, contra 7 µs com o validador de formato. Só o CPF estava preenchido, e a
  comparação não é de igual para igual (um validador contra cinco). Há espaço para otimizar: `CPF.valid?` aloca de
  45 a 64 objetos por chamada.
- A leitura com e sem os tipos da gem não mostrou custo perceptível. A medição com a gem rodou depois da outra, com o
  cache do banco aquecido, então a vantagem observada não é significativa.
- A memória medida é dominada pelos dados que o próprio teste mantém, e não permite comparação.

## Defeitos

### 1. Formulário de edição rejeita o próprio valor salvo

Um registro lido do banco aparece no `text_field` como `1234.5` e `2026-01-05`. Reenviar **sem mudar nada** falha:
`Amount is not a valid amount in Brazilian reais` e `Due on is not a valid date`. Reproduzido com Rails 6.0 e 8.0.
O README sugere preencher o campo com `Currency.format` e `DateFormat.format`, mas o comportamento padrão deveria
funcionar.

### 2. Valor legítimo do banco é considerado inválido

Numa coluna `decimal(16,4)`, o registro com `10.1234` é lido corretamente, mas `valid?` devolve `false`. Qualquer
atualização desse registro é bloqueada.

## Riscos de uso

| Comportamento | Observação |
|---|---|
| `insert_all`, `update_all` e `update_column` com texto inválido gravam `NULL` | Esses métodos pulam validações no Rails, mas aqui o dado se perde sem aviso |
| `where` com texto inválido vira `= NULL` e não encontra nada | Inclui o formato ISO (`"2026-12-31"`) |
| O mesmo CPF é salvo com e sem máscara, e a busca encontra só um | A gem valida, mas não padroniza antes de gravar |
| CPF inválido já existente no banco impede atualizar outros campos | Comportamento padrão de validações; vale documentar `if: :cpf_changed?` |

## O que funcionou sem ressalvas

Registro automático pelo Railtie, `eager_load` em produção, mensagens em pt-BR, somas, médias, ordenação,
agrupamento, consultas com texto brasileiro válido e com faixas de `Date`, parâmetros inesperados em formulários,
`Float` em JSON recusado, BR Code gerado por HTTP e lido de volta, primeiro uso concorrente dos módulos carregados
sob demanda e 10 mil CPFs e CNPJs gerados fora da gem (mais 20 mil adulterados, todos rejeitados).

## Limites destes testes

- Dados sintéticos. Não foram usados dados pessoais nem bases de terceiros.
- Não cobrem bancos além de PostgreSQL e MySQL, JRuby, nem uso prolongado em produção.
