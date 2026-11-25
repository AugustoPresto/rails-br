# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

### Adicionado
- `RailsBr::Pix::Key`: detecção do tipo (`:cpf`, `:cnpj`, `:phone`, `:email`, `:evp`) e validação estrita
  da chave Pix, conforme os manuais do Banco Central.
- Validador ActiveModel `validates :pix_key, pix_key: true`, com mensagens em `pt-BR` e `en`.
- `RailsBr::CNPJ`: suporte ao CNPJ numérico e ao alfanumérico da Receita Federal, com `alphanumeric?`,
  máscara, normalização para maiúsculas e `parse!`.
- Validador ActiveModel `validates :cnpj, cnpj: true`, com mensagens em `pt-BR` e `en`.
- `RailsBr::Document`: base comum de CPF e CNPJ (igualdade, `to_s`, `parse!`).
- `RailsBr::CPF`: value object imutável com validação (módulo 11), máscara e `parse!`.
- Validador ActiveModel `validates :cpf, cpf: true`, com mensagens em `pt-BR` e `en`.
- Esqueleto do projeto: gemspec, estrutura `lib/`, RSpec, RuboCop, Appraisal e CI.
