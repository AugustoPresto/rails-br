# rails-br

[![CI](https://github.com/AugustoPresto/rails-br/actions/workflows/ci.yml/badge.svg)](https://github.com/AugustoPresto/rails-br/actions/workflows/ci.yml)
[![Licença: MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-blue.svg)](LICENSE.txt)
![Ruby](https://img.shields.io/badge/ruby-%E2%89%A5%202.7-red.svg)
![Rails](https://img.shields.io/badge/rails-%E2%89%A5%206.0%20(opcional)-red.svg)

Helpers brasileiros para Ruby e Rails: **CPF**, **CNPJ** (inclusive o alfanumérico) e **Pix** (chaves e BR Code).
Sucessora moderna da [Brazilian Rails](https://github.com/tapajos/brazilian-rails), arquivada desde 2018.

> **Status:** versão 0.1.0. A API pode mudar até a 1.0, seguindo o [SemVer](https://semver.org/lang/pt-BR/).

## Por que esta gem

- **Sem monkey patching.** Nada de reabrir `String`, `Numeric` ou `Date`. Usamos value objects
  (`RailsBr::CPF.new("...")`) e validadores ActiveModel.
- **Núcleo em Ruby puro.** O Rails é opcional; a integração (Railtie, I18n, validadores) só é carregada
  quando ele está presente.
- **Segue a documentação oficial.** O CNPJ alfanumérico segue a Receita Federal, e o Pix segue os manuais do
  Banco Central. O CRC16 reproduz todos os exemplos oficiais, e o payload gerado é idêntico ao do manual.
- **Retrocompatível.** Ruby 2.7 a 3.4 e Rails 6.0 a 8.0, testados no CI.
- **Dinheiro com `BigDecimal`**, nunca `Float`.

## Instalação

A gem ainda não está no RubyGems. Por enquanto, instale pelo Git, fixando a versão:

```ruby
# Gemfile
gem "rails-br", github: "AugustoPresto/rails-br", tag: "v0.1.0"
```

Não há dependências de runtime além do `bigdecimal`. O Rails (`activemodel`) só é necessário se você
usar os validadores.

## Recursos

| Recurso | Classe | Para quê |
|---|---|---|
| CPF | `RailsBr::CPF` | Validar e formatar |
| CNPJ | `RailsBr::CNPJ` | Validar e formatar, no formato numérico e no alfanumérico |
| Chave Pix | `RailsBr::Pix::Key` | Detectar o tipo e validar (CPF, CNPJ, telefone, e-mail, chave aleatória) |
| BR Code | `RailsBr::Pix::BRCode` | Ler, validar e gerar o "Pix copia e cola" |
| ActiveModel | `cpf`, `cnpj`, `pix_key` | Validadores com mensagens em `pt-BR` e `en` |

Todas as classes são carregadas sob demanda: `require "rails_br"` registra tudo, e cada módulo só é lido do
disco no primeiro uso.

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

A entrada é tolerante: aceita máscara e espaços. Apenas `.`, `-` e espaços são removidos. Zeros à esquerda
perdidos em um `Integer` **não** são completados: use `String`.

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

O cálculo segue a Receita Federal: módulo 11, pesos de 2 a 9 e valor ASCII de cada caractere menos 48.
Os 2 dígitos verificadores são sempre numéricos.

### Chave Pix

```ruby
key = RailsBr::Pix::Key.new("+5561912345678")
key.valid?  # => true
key.type    # => :phone   (:cpf, :cnpj, :phone, :email ou :evp)

RailsBr::Pix::Key.type_of("123e4567-e12b-12d1-a456-426655440000")  # => :evp
RailsBr::Pix::Key.valid?("111.444.777-35")  # => false (use só os dígitos)
RailsBr::Pix::Key.parse!("lixo")            # => raises RailsBr::InvalidValueError
```

A validação é **estrita**, como no DICT do Banco Central, e não normaliza a chave:

| Tipo | Formato |
|---|---|
| `:cpf` | 11 dígitos, sem máscara, com dígitos verificadores corretos |
| `:cnpj` | 14 caracteres (numérico ou alfanumérico), sem máscara, com dígitos verificadores corretos |
| `:phone` | formato internacional E.164 (`+5561912345678`); o `+55` não é exigido pela especificação |
| `:email` | até 77 caracteres, em minúsculas |
| `:evp` | chave aleatória: UUID com hífens, em minúsculas |

### BR Code ("Pix copia e cola")

Para **ler e validar** um payload:

```ruby
code = RailsBr::Pix::BRCode.new(payload)
code.valid?     # => true (estrutura, CRC16 e regras do Pix)
code.static?    # => true se tem chave Pix; code.dynamic? se tem URL
code.key        # => #<RailsBr::Pix::Key> (code.key.type => :evp)
code.name       # => "Fulano de Tal"
code.city       # => "BRASILIA"
code.amount     # => BigDecimal("100.50") ou nil
code.txid       # => "ABC123" (nil quando o payload traz "***")

RailsBr::Pix::BRCode.new("lixo").error  # => motivo da invalidez
RailsBr::Pix::BRCode.parse!(payload)    # => raises RailsBr::InvalidValueError (com o motivo)
RailsBr::Pix::CRC16.checksum("...6304") # => "1D3D"
```

Lê QR Codes estáticos, dinâmicos e com recorrência. Espaços e quebras de linha nas pontas são ignorados.

Para **gerar** o "Pix copia e cola" de uma chave fixa (QR Code estático):

```ruby
require "bigdecimal"

code = RailsBr::Pix::BRCode.static(
  key: "123e4567-e12b-12d1-a456-426655440000",
  name: "Fulano de Tal",
  city: "Brasília",              # acentos são removidos
  amount: BigDecimal("100.50"),  # opcional; BigDecimal, Integer ou String, nunca Float
  txid: "PEDIDO42",              # opcional (1 a 25 letras ou dígitos)
  info: "Pedido 42"              # opcional
)
code.to_s    # => "00020126580014br.gov.bcb.pix0136...6304XXXX"
code.valid?  # => true
```

Sem `txid`, o payload leva `***`. Nome e cidade precisam caber em 25 e 15 caracteres ASCII, depois de
remover os acentos. Dados inválidos levantam `RailsBr::InvalidValueError`.

> A gem **gera e lê** o payload, mas não desenha o QR Code. Use uma biblioteca de QR Code (como `rqrcode`) sobre
> o texto de `code.to_s`.

### Validação no ActiveModel / Rails

```ruby
class Company < ApplicationRecord
  validates :cpf, presence: true, cpf: true
  validates :cnpj, presence: true, cnpj: true
  validates :pix_key, presence: true, pix_key: true
end
```

No Rails, os validadores e as traduções (`pt-BR` e `en`) são carregados automaticamente. Fora do Rails, use
`require "rails_br/validators"` (requer `activemodel`). Valores em branco são ignorados; combine com
`presence: true` para exigir o campo.

As mensagens ficam em `errors.messages.invalid_cpf`, `invalid_cnpj` e `invalid_pix_key`, e podem ser
sobrescritas no `config/locales` da sua aplicação ou com `message:`.

## Erros

Todos os erros herdam de `RailsBr::Error`. Os métodos `valid?` nunca levantam exceção; os `parse!` e o
`BRCode.static` levantam `RailsBr::InvalidValueError` com a descrição do problema.

## Compatibilidade

Núcleo testado em Ruby 2.7, 3.0, 3.1, 3.2, 3.3 e 3.4. Com Rails, o CI cobre as combinações oficialmente
compatíveis:

| Ruby | Rails |
|---|---|
| 2.7 | 6.0, 6.1, 7.0, 7.1 |
| 3.0 | 6.1, 7.0 |
| 3.1 | 7.0, 7.1, 7.2 |
| 3.2 | 7.1, 7.2, 8.0 |
| 3.3 | 7.2, 8.0 |
| 3.4 | 7.2, 8.0 |

## Fontes oficiais

- Receita Federal: [perguntas e respostas sobre o CNPJ alfanumérico](https://www.gov.br/receitafederal/pt-br/centrais-de-conteudo/publicacoes/perguntas-e-respostas/cnpj/cnpj-alfanumerico.pdf)
- Banco Central: Manual de Padrões para Iniciação do Pix (v2.10.0), Manual do BR Code (v2.0.0), Manual Operacional do
  DICT (v8.5) e API do DICT (v2.13.0)

## Roadmap

| Versão | Conteúdo |
|---|---|
| 0.1.0 | CPF, CNPJ (com alfanumérico), chave Pix, BR Code estático e validadores ActiveModel |
| 0.2.0 | Moeda (`BigDecimal`) e número por extenso |
| 0.3.0 | CEP (máscara e formato), dias úteis e feriados |
| 0.4.0 | Boleto e linha digitável |

Fora do escopo por enquanto: consultas a APIs externas (como ViaCEP), Pix dinâmico e integração com PSPs.

## Desenvolvimento

```bash
bundle install
bundle exec rspec                       # testes (cobertura mínima: 95% de linhas)
bundle exec rubocop                     # lint (Ruby 3.3 ou superior)
bundle exec yard stats --list-undoc     # documentação deve ficar em 100%
bundle exec appraisal generate          # regenera os gemfiles por versão do Rails
```

Para testar numa versão específica do Rails:

```bash
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails_7_1.gemfile bundle exec rspec
```

O código precisa rodar em Ruby 2.7: nada de pattern matching, endless methods ou `Data.define`. O RuboCop
(`TargetRubyVersion: 2.7`) avisa se isso acontecer.

## Contribuindo

Issues e pull requests são bem-vindos. Prefira PRs pequenos e focados, com testes, e mensagens de commit no
padrão [Conventional Commits](https://www.conventionalcommits.org/pt-br/).

## Licença

[MIT](LICENSE.txt). Inspirada na ideia da Brazilian Rails (Marcos Tapajós e colaboradores); o código é escrito do
zero.
