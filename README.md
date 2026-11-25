# rails-br

[![CI](https://github.com/AugustoPresto/rails-br/actions/workflows/ci.yml/badge.svg)](https://github.com/AugustoPresto/rails-br/actions/workflows/ci.yml)

Helpers brasileiros para Ruby e Rails: CPF/CNPJ (incluindo o CNPJ alfanumérico), Pix, moeda e CEP.
Sucessora moderna da [Brazilian Rails](https://github.com/tapajos/brazilian-rails), arquivada desde 2018.

> **Status:** em desenvolvimento (pré-0.1.0). A API ainda não é estável.

## Princípios

- **Sem monkey patching.** Nada de reabrir `String`, `Numeric` ou `Date`. Usamos value objects
  (`RailsBr::CPF.new("...")`) e validadores ActiveModel.
- **Núcleo em Ruby puro.** O Rails é opcional; a integração (Railtie, I18n, validadores) só é
  carregada quando ele está presente.
- **Módulos sob demanda.** Carregue só o que precisa, por exemplo `require "rails_br/cpf"`.
- **Retrocompatível.** Ruby ≥ 2.7 e Rails ≥ 6.0.
- **Dinheiro com `BigDecimal`**, nunca `Float`.

## Roadmap

| Versão | Conteúdo |
|---|---|
| 0.1.0 | CPF/CNPJ (com alfanumérico) + validador ActiveModel; Pix (chave e BR Code estático) |
| 0.2.0 | Moeda (`BigDecimal`) e número por extenso |
| 0.3.0 | CEP (máscara e formato), dias úteis e feriados |
| 0.4.0 | Boleto e linha digitável |

## Instalação

Ainda não publicada no RubyGems. Por enquanto, via Git:

```ruby
gem "rails-br", github: "AugustoPresto/rails-br"
```

## Desenvolvimento

```bash
bundle install
bundle exec rspec        # testes
bundle exec rubocop      # lint (Ruby 3.4)
bundle exec appraisal generate   # regenera os gemfiles por versão do Rails
```

Para testar numa versão específica do Rails:

```bash
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle exec rspec
```

## Licença

[MIT](LICENSE.txt). Inspirada na ideia da Brazilian Rails (Marcos Tapajós e colaboradores); o código
é escrito do zero.
