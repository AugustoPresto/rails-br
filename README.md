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

## Uso

### CPF

```ruby
require "rails_br"

cpf = RailsBr::CPF.new("111.444.777-35")
cpf.valid?      # => true
cpf.digits      # => "11144477735"
cpf.formatted   # => "111.444.777-35"

RailsBr::CPF.valid?("111.111.111-11")  # => false (sequência repetida)
RailsBr::CPF.valid?(nil)               # => false
RailsBr::CPF.parse!("123")             # => raises RailsBr::InvalidValueError
```

A entrada é tolerante: aceita máscara e espaços. Apenas `.`, `-` e espaços são removidos.
Zeros à esquerda perdidos em um `Integer` **não** são completados: use `String`.

### CNPJ (numérico e alfanumérico)

```ruby
cnpj = RailsBr::CNPJ.new("12.ABC.345/01DE-35")
cnpj.valid?         # => true
cnpj.alphanumeric?  # => true
cnpj.formatted      # => "12.ABC.345/01DE-35"
cnpj.to_s           # => "12ABC34501DE35"

RailsBr::CNPJ.valid?("11.222.333/0001-81")  # => true (formato numérico)
RailsBr::CNPJ.valid?("12.abc.345/01de-35")  # => true (minúsculas são normalizadas)
RailsBr::CNPJ.parse!("123")                 # => raises RailsBr::InvalidValueError
```

O cálculo segue a Receita Federal: módulo 11, pesos de 2 a 9 e valor ASCII de cada caractere
menos 48. Os 2 dígitos verificadores são sempre numéricos.

### Chave Pix

```ruby
key = RailsBr::Pix::Key.new("+5561912345678")
key.valid?  # => true
key.type    # => :phone   (:cpf, :cnpj, :phone, :email ou :evp)

RailsBr::Pix::Key.type_of("123e4567-e12b-12d1-a456-426655440000")  # => :evp
RailsBr::Pix::Key.valid?("111.444.777-35")  # => false (use só os dígitos)
RailsBr::Pix::Key.parse!("lixo")            # => raises RailsBr::InvalidValueError
```

A validação é **estrita**, como no DICT do Banco Central, e não normaliza a chave: CPF e CNPJ sem
máscara; e-mail e chave aleatória em minúsculas; telefone no formato internacional E.164. O `+55` não é
exigido pela especificação. Os formatos seguem o Manual Operacional do DICT (v8.5), a API do DICT
(v2.13.0) e o Manual de Padrões para Iniciação do Pix (v2.10.0).

### Validação no ActiveModel / Rails

```ruby
class Company < ApplicationRecord
  validates :cpf, presence: true, cpf: true
  validates :cnpj, presence: true, cnpj: true
  validates :pix_key, presence: true, pix_key: true
end
```

No Rails o validador e as traduções (`pt-BR` e `en`) são carregados automaticamente.
Fora do Rails, use `require "rails_br/validators"` (requer `activemodel`).
Valores em branco são ignorados; combine com `presence: true` para exigir o campo.

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
