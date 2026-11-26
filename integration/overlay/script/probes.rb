# Sondagem de comportamentos de risco: registra o que de fato acontece, sem
# presumir o resultado. Uso: bin/rails runner script/probes.rb saida.json
require "json"

results = {}
probe = lambda do |name, &block|
  ActiveRecord::Base.transaction do
    results[name] = block.call
  rescue StandardError => e
    results[name] = "exceção: #{e.class}: #{e.message.lines.first.to_s.strip[0, 160]}"
  ensure
    raise ActiveRecord::Rollback
  end
end

probe.call("insert_all com texto inválido") do
  Order.insert_all([{ amount: "abc", due_on: "31/02/2026" }])
  row = Order.order(:id).last
  { gravou: !row.nil?, amount: row&.amount&.to_s, due_on: row&.due_on&.to_s }
end

probe.call("insert_all com texto brasileiro válido") do
  Order.insert_all([{ amount: "R$ 1,50", due_on: "01/02/2026" }])
  row = Order.order(:id).last
  { amount: row.amount.to_s("F"), due_on: row.due_on.to_s }
end

probe.call("update_all com texto inválido") do
  order = Order.create!(amount: "10,00", due_on: "01/01/2026")
  Order.where(id: order.id).update_all(amount: "10.00", due_on: "2026-12-31")
  order.reload
  { amount: order.amount&.to_s("F"), due_on: order.due_on&.to_s }
end

probe.call("where com texto inválido") do
  Order.create!(amount: nil, due_on: nil)
  Order.create!(amount: "10,00", due_on: "31/12/2026")
  { registros_com_data_iso: Order.where(due_on: "2026-12-31").count,
    registros_com_valor_americano: Order.where(amount: "10.00").count,
    sql: Order.where(due_on: "2026-12-31").to_sql[/WHERE .*/] }
end

probe.call("update_column com texto inválido") do
  order = Order.create!(amount: "10,00")
  order.update_column(:amount, "abc")
  { amount: order.reload.amount&.to_s("F") }
end

probe.call("registro com 4 casas decimais lido do banco") do
  Entry.connection.execute("INSERT INTO entries (amount) VALUES (10.1234)")
  entry = Entry.last
  { amount: entry.amount.to_s("F"), valido: entry.valid?, erros: entry.errors.full_messages }
end

probe.call("mesmo CPF com e sem máscara") do
  a = Customer.create!(name: "a", cpf: "111.444.777-35")
  b = Customer.create!(name: "b", cpf: "11144477735")
  { valores_gravados: [a.reload.cpf, b.reload.cpf], busca_sem_mascara: Customer.where(cpf: "11144477735").count }
end

probe.call("CPF numérico (Integer) em coluna de texto") do
  customer = Customer.new(name: "a", cpf: 11_144_477_735)
  { valido: customer.valid?, gravado: customer.cpf }
end

probe.call("dado legado inválido no banco") do
  Customer.connection.execute("INSERT INTO customers (name, cpf) VALUES ('legado', '000.000.000-00')")
  customer = Customer.find_by!(name: "legado")
  { valido: customer.valid?, atualiza_outro_campo: customer.update(name: "novo") }
end

probe.call("presence junto com texto inválido") do
  record = Order.new(amount: "abc")
  record.valid?
  { amount: record.amount, before_type_cast: record.amount_before_type_cast }
end

probe.call("serialização JSON") do
  order = Order.new(amount: "1.234,50", due_on: "05/01/2026")
  order.as_json.slice("amount", "due_on")
end

probe.call("formulário: valor exibido após ler do banco") do
  order = Order.find(Order.create!(amount: "1.234,50", due_on: "05/01/2026").id)
  { due_on_before_type_cast: order.due_on_before_type_cast.to_s,
    amount_before_type_cast: order.amount_before_type_cast.to_s }
end

payload = { ruby: RUBY_VERSION, rails: Rails.version, banco: ActiveRecord::Base.connection.adapter_name, probes: results }
File.write(ARGV.fetch(0), JSON.pretty_generate(payload))
puts JSON.pretty_generate(payload)
