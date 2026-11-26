# Teste de carga com 1 milhão de registros. Compara o mesmo trabalho com e sem a
# gem. Uso: bin/rails runner script/scale.rb saida.json
require "json"
require Rails.root.join("test/e2e/fake_documents").to_s

ROWS = Integer(ENV.fetch("ROWS", 1_000_000))
BATCH = 10_000

class PlainOrder < ActiveRecord::Base
  self.table_name = "orders"
end

class PlainCustomer < ActiveRecord::Base
  self.table_name = "customers"
end

# Referência: um validador nativo do Rails que só confere o formato.
class FormatCustomer < ActiveRecord::Base
  self.table_name = "customers"
  validates :cpf, format: { with: /\A\d{11}\z/ }, allow_blank: true
end

def rss_mb
  File.read("/proc/self/status")[/VmRSS:\s+(\d+)/, 1].to_i / 1024
end

def measure(results, name, count)
  GC.start
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  allocated = GC.stat(:total_allocated_objects)
  yield
  seconds = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  results[name] = {
    registros: count, segundos: seconds.round(2), por_segundo: (count / seconds).round,
    objetos_por_registro: ((GC.stat(:total_allocated_objects) - allocated) / count.to_f).round(1), rss_mb: rss_mb
  }
  puts "#{name}: #{results[name]}"
  $stdout.flush
end

results = {}
random = Random.new(2026)
cpfs = Array.new(ROWS) { FakeDocuments.cpf(random) }
amounts = Array.new(ROWS) { BigDecimal(random.rand(1..100_000_000)) / 100 }
texts = amounts.map { |a| RailsBr::Currency.format(a) }
base = Date.new(2020, 1, 1)

measure(results, "gerar clientes (insert_all)", ROWS) do
  cpfs.each_slice(BATCH).with_index do |slice, b|
    Customer.insert_all(slice.each_with_index.map { |cpf, i| { name: "c#{b * BATCH + i}", cpf: cpf } })
  end
end

measure(results, "gravar pedidos com BigDecimal e Date (insert_all, sem a gem)", ROWS) do
  amounts.each_slice(BATCH).with_index do |slice, b|
    PlainOrder.insert_all(slice.each_with_index.map { |a, i| { amount: a, due_on: base + ((b * BATCH + i) % 3000) } })
  end
end
PlainOrder.delete_all

measure(results, "gravar pedidos com texto brasileiro (insert_all, com a gem)", ROWS) do
  texts.each_slice(BATCH).with_index do |slice, b|
    Order.insert_all(slice.each_with_index.map do |text, i|
      { amount: text, due_on: RailsBr::DateFormat.format(base + ((b * BATCH + i) % 3000)) }
    end)
  end
end
expected_sum = amounts.sum
results["conferência"] = {
  pedidos: Order.count, nulos: Order.where(amount: nil).or(Order.where(due_on: nil)).count,
  soma_confere: Order.sum(:amount) == expected_sum
}
puts "conferência: #{results['conferência']}"

measure(results, "ler pedidos (sem a gem)", ROWS) do
  PlainOrder.find_each(batch_size: BATCH) { |o| o.amount && o.due_on }
end
measure(results, "ler pedidos (com a gem)", ROWS) do
  Order.find_each(batch_size: BATCH) { |o| o.amount && o.due_on }
end

sample = [ROWS, 200_000].min
measure(results, "valid? em clientes (sem validadores)", sample) do
  PlainCustomer.limit(sample).find_each(batch_size: BATCH, &:valid?)
end
measure(results, "valid? em clientes (validador de formato do Rails)", sample) do
  FormatCustomer.limit(sample).find_each(batch_size: BATCH, &:valid?)
end
invalid = 0
measure(results, "valid? em clientes (com os validadores)", sample) do
  Customer.limit(sample).find_each(batch_size: BATCH) { |c| invalid += 1 unless c.valid? }
end
results["clientes inválidos"] = invalid

measure(results, "CPF.valid? puro", ROWS) { cpfs.each { |c| raise c unless RailsBr::CPF.valid?(c) } }
measure(results, "Currency.parse puro", ROWS) do
  texts.each_with_index { |t, i| raise t unless RailsBr::Currency.parse(t) == amounts[i] }
end
brcodes = [ROWS, 100_000].min
measure(results, "BR Code: gerar e validar", brcodes) do
  brcodes.times do |i|
    code = RailsBr::Pix::BRCode.static(key: "pix@example.com", name: "Loja", city: "Goiania", amount: amounts[i])
    raise "inválido" unless code.valid?
  end
end

File.write(ARGV.fetch(0), JSON.pretty_generate(ruby: RUBY_VERSION, rails: Rails.version, resultados: results))
