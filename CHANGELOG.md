# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

### Adicionado
- `RailsBr::CPF`: value object imutável com validação (módulo 11), máscara e `parse!`.
- Validador ActiveModel `validates :cpf, cpf: true`, com mensagens em `pt-BR` e `en`.
- Esqueleto do projeto: gemspec, estrutura `lib/`, RSpec, RuboCop, Appraisal e CI.
