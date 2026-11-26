# Uso sem Rails: carrega a gem publicada num Ruby puro e exercita cada módulo.
require "bigdecimal"
require "date"
require "rails-br"

def check(label, condition)
  abort "FALHOU: #{label}" unless condition
end

check "Rails ausente", !defined?(Rails)
check "CPF", RailsBr::CPF.valid?("111.444.777-35") && !RailsBr::CPF.valid?("111.111.111-11")
check "CNPJ", RailsBr::CNPJ.valid?("12.ABC.345/01DE-35")
check "chave Pix", RailsBr::Pix::Key.type_of("+5561912345678") == :phone
code = RailsBr::Pix::BRCode.static(key: "pix@example.com", name: "São João", city: "Goiânia",
                                   amount: BigDecimal("10.5"))
check "BR Code", code.valid? && code.name == "Sao Joao"
check "moeda", RailsBr::Currency.parse(RailsBr::Currency.format(BigDecimal("1234.56"))) == BigDecimal("1234.56")
check "data", RailsBr::DateFormat.parse("31/12/2026") == Date.new(2026, 12, 31)

# Primeiro uso simultâneo, em várias threads, de módulos carregados sob demanda.
script = 'require "rails-br"; 32.times.map { Thread.new { RailsBr::Pix::BRCode.valid?("x") || ' \
         'RailsBr::CNPJ.valid?("11222333000181") } }.each { |t| abort "thread" unless t.value }'
check "autoload concorrente", 20.times.all? { system(RbConfig.ruby, "-e", script) }

puts "OK ruby #{RUBY_VERSION} rails-br #{RailsBr::VERSION}"
