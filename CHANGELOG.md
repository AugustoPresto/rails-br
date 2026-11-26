# Changelog

Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
versionamento [SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

## [0.2.1] - 2026-11-26

### Alterado
- A dependência `bigdecimal` passa a ter teto (`>= 2.0`, `< 5`), o que elimina o aviso do `gem build`.
- README do pacote atualizado: instalação pelo RubyGems.

## [0.2.0] - 2026-11-26

### Adicionado
- Tipos de atributo `:br_currency` e `:br_date` (ActiveModel e ActiveRecord) e validadores
  `br_currency: true` e `br_date: true`, que acusam texto inválido.
- `RailsBr::DateFormat`: leitura estrita (`parse`, `parse!`) e formatação (`format`) de datas `dd/mm/aaaa`.
- `RailsBr::Currency`: leitura estrita (`parse`, `parse!`) e formatação (`format`) de valores em reais, sempre
  com `BigDecimal`.

## [0.1.0] - 2026-11-25

### Adicionado
- `RailsBr::Pix::BRCode.static`: geração do BR Code estático ("Pix copia e cola") com valor (`BigDecimal`,
  `Integer` ou `String`, nunca `Float`), `txid` e `infoAdicional`; remove acentos de nome e cidade e valida
  tamanhos. Reproduz byte a byte o exemplo oficial do Banco Central.
- `RailsBr::Pix::BRCode`: leitura e validação do "Pix copia e cola" (TLV/EMV, CRC16, campos obrigatórios e
  regras do Pix), com `key`, `url`, `name`, `city`, `amount` (`BigDecimal`), `txid`, `info`, `static?` e `dynamic?`.
- `RailsBr::Pix::CRC16` (CCITT-FALSE) e `RailsBr::Pix::TLV`.
- Dependência de runtime em `bigdecimal` (bundled gem a partir do Ruby 3.4).
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
