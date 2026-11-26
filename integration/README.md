# Testes em aplicações Rails reais

O CI testa a gem isolada. Aqui cada combinação de Ruby e Rails gera um app com `rails new`, instala a **gem
publicada no RubyGems** e roda contra um banco de verdade. Requer Docker com Compose.

```bash
./run.sh                  # matriz completa: PostgreSQL, MySQL e Ruby sem Rails
./run.sh 3.4 8.0          # uma combinação (PostgreSQL)
./run.sh 3.4 8.0 mysql    # uma combinação com MySQL
./run.sh scale 3.4 8.0    # carga com 1 milhão de registros
```

`RAILS_BR_VERSION=0.3.0 ./run.sh` escolhe a versão da gem. Os testes de formulário e de casas decimais
exigem a 0.3.0 ou mais nova. Os resultados ficam em `results/` (fora do Git).

## O que é verificado

| Etapa | Conteúdo |
|---|---|
| Testes do app | Boot e `eager_load`, validadores e tipos pelo Railtie, mensagens em pt-BR, gravação e releitura, agregações e consultas, reenvio do formulário de edição, valores com 4 casas, formulários HTTP, parâmetros inesperados e 10 mil documentos gerados fora da gem |
| Sondagem | Registra o comportamento em casos de risco (`insert_all`, `update_all`, consultas, dados legados) |
| Produção | Puma com 16 threads e 3.200 requisições simultâneas, com cada resposta conferida |
| Sem Rails | A gem num Ruby puro, incluindo o primeiro uso concorrente dos módulos carregados sob demanda |
| Carga | 1 milhão de registros, comparando o mesmo trabalho com e sem a gem |

Todos os dados são sintéticos. Os documentos vêm de geradores próprios do teste, para a gem não validar o
próprio cálculo.
