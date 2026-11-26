# Relatório: rails-br 0.3.0 em aplicações Rails reais

Executado em 26/11/2026 com a gem publicada no RubyGems. Como reproduzir: [README](README.md).

## Resumo

- A gem **funcionou em todas as combinações declaradas** de Ruby e Rails, sem falha em testes ou sob concorrência.
- Os **dois defeitos** encontrados na 0.2.1 por estes testes foram corrigidos na 0.3.0 e não se repetiram em nenhuma
  execução.
- Continuam os riscos de uso descritos abaixo, que precisam de código ou documentação.

## Matriz

| O quê | Execuções | Resultado |
|---|---|---|
| Apps Rails com PostgreSQL 15 | 16 combinações Ruby × Rails (2.7 a 3.4, 6.0 a 8.0) | todas passaram |
| Apps Rails com MySQL 8.0 | Ruby 2.7/Rails 6.0, 3.1/7.0 e 3.4/8.0 | todas passaram |
| Ruby sem Rails | 2.7, 3.0, 3.1, 3.2, 3.3 e 3.4 | todas passaram |

Cada app roda 18 testes (cerca de 40 mil asserções) e, em produção, com Puma e 16 threads, 3.200 requisições de
32 clientes simultâneos. Nas 19 execuções com Rails foram **342 testes sem falha** e **60.800 requisições sem
nenhuma resposta incorreta**.

## Carga com 1 milhão de registros (PostgreSQL)

Uma execução por combinação, numa única máquina (8 núcleos). Servem de ordem de grandeza: operações que não passam
pela gem variaram até 13% em relação à execução anterior.

| Operação (por segundo) | Ruby 2.7, Rails 6.0 | Ruby 3.4, Rails 8.0 |
|---|---|---|
| `insert_all` com `BigDecimal` e `Date`, sem a gem | 38.966 | 51.768 |
| `insert_all` com texto brasileiro, com a gem ¹ | 35.298 | 44.560 |
| `valid?` sem validadores | 109.492 | 175.761 |
| `valid?` com um validador de formato do Rails | 70.703 | 135.295 |
| `valid?` com os 5 validadores da gem ² | 16.258 | 38.048 |
| `CPF.valid?` isolado | 136.650 | 128.664 |
| `Currency.parse` isolado ³ | 418.617 | 527.819 |
| Gerar e validar um BR Code | 4.945 | 14.436 |

- Nos pedidos gravados por texto, nenhum campo ficou nulo e a soma no banco conferiu com a calculada em Ruby.
- ¹ De 10% a 14% mais lento, incluindo no tempo a formatação das datas em texto feita pelo próprio teste.
- ² Na 3.4, cerca de 26 µs por registro, contra 7 µs com o validador de formato. Só o CPF estava preenchido, e a
  comparação não é de igual para igual (um validador contra cinco). Há espaço para otimizar: `CPF.valid?` aloca de
  45 a 64 objetos por chamada.
- ³ A 0.3.0 aloca um objeto a mais por leitura que a 0.2.1. A diferença de velocidade entre as duas execuções está
  próxima da variação da máquina.
- A leitura com e sem os tipos da gem não mostrou custo perceptível. A medição com a gem rodou depois da outra, com o
  cache do banco aquecido, então a vantagem observada não é significativa.
- A memória medida é dominada pelos dados que o próprio teste mantém, e não permite comparação.

## Defeitos da 0.2.1, corrigidos na 0.3.0

| Na 0.2.1 | Na 0.3.0 |
|---|---|
| O formulário de edição mostrava `1234.5` e `2026-01-05`, e reenviar sem mudar nada era rejeitado | Os campos mostram `1.234,50` e `05/01/2026`, e o reenvio é válido e não altera o registro |
| Um valor `10.1234` numa coluna `decimal(16,4)` fazia `valid?` devolver `false` | O registro é válido e atualizável; com `scale: 4`, o valor é gravado, lido e consultado |

## Riscos de uso

| Comportamento | Observação |
|---|---|
| `insert_all`, `update_all` e `update_column` com texto inválido gravam `NULL` | Esses métodos pulam validações no Rails, mas aqui o dado se perde sem aviso |
| `where` com texto inválido vira `= NULL` e não encontra nada | Inclui o formato ISO (`"2026-12-31"`) |
| Em JSON, os valores saem como `"1234.5"` e `"2026-01-05"` | Devolvidos assim à aplicação, são rejeitados; formate com os métodos da gem |
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
