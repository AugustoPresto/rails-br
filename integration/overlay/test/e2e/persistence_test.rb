require_relative "support"

class PersistenceTest < ActiveSupport::TestCase
  def attributes
    {
      name: "Cliente", cpf: FakeDocuments.cpf, cnpj: FakeDocuments.cnpj(alphanumeric: true),
      pix_key: "cliente@example.com", birth_on: "31/12/1990", credit_limit: "R$ 12.345,67"
    }
  end

  test "grava texto brasileiro e lê tipos Ruby do banco" do
    customer = Customer.find(Customer.create!(attributes).id)

    assert_equal Date.new(1990, 12, 31), customer.birth_on
    assert_equal BigDecimal("12345.67"), customer.credit_limit
    assert customer.valid?, customer.errors.full_messages.join(", ")
    refute customer.changed?
  end

  test "atualiza registros e detecta alterações só quando o valor muda" do
    customer = Customer.create!(attributes)

    customer.assign_attributes(credit_limit: "12.345,67", birth_on: "31/12/1990")
    refute customer.changed?

    customer.update!(credit_limit: "-0,01")
    assert_equal BigDecimal("-0.01"), customer.reload.credit_limit
  end

  test "rejeita dados inválidos com todas as mensagens em pt-BR" do
    I18n.with_locale(:"pt-BR") do
      customer = Customer.new(name: "x", cpf: "111.111.111-11", cnpj: "123", pix_key: "lixo",
                              birth_on: "31/02/1990", credit_limit: "1234.56")

      refute customer.save
      assert_equal %i[birth_on cnpj cpf credit_limit pix_key], customer.errors.messages.keys.sort
      assert_includes customer.errors[:credit_limit], "não é um valor em reais válido"
    end
  end

  test "somas, médias, ordenação e agrupamento usam BigDecimal e Date" do
    customer = Customer.create!(name: "x")
    ["1.000,10", "2.000,20", "3.000,30"].each_with_index do |amount, i|
      customer.orders.create!(amount: amount, due_on: "0#{i + 1}/03/2026")
    end

    assert_equal BigDecimal("6000.60"), customer.orders.sum(:amount)
    assert_equal BigDecimal("2000.20"), customer.orders.average(:amount)
    assert_equal BigDecimal("3000.30"), customer.orders.maximum(:amount)
    assert_equal Date.new(2026, 3, 1), customer.orders.minimum(:due_on)
    assert_equal [BigDecimal("1000.10")], customer.orders.order(:due_on).limit(1).pluck(:amount)
    assert_equal 3, Order.group(:due_on).count.keys.grep(Date).length
  end

  test "consultas com texto brasileiro, Date, faixas e find_by" do
    order = Order.create!(amount: "R$ 50,00", due_on: "15/06/2026")

    assert_equal order, Order.find_by(due_on: "15/06/2026")
    assert_equal order, Order.find_by(amount: "50,00")
    assert_equal [order], Order.where(due_on: Date.new(2026, 6, 1)..Date.new(2026, 6, 30)).to_a
    assert_equal [order], Order.where("amount > ?", BigDecimal("49.99")).to_a
  end

  test "valor gravado com 4 casas não bloqueia a atualização do registro" do
    Entry.connection.execute("INSERT INTO entries (amount) VALUES (10.1234)")
    entry = Entry.last

    assert_equal BigDecimal("10.1234"), entry.amount
    assert entry.valid?, entry.errors.full_messages.join(", ")
    entry.amount = BigDecimal("1.005")
    refute entry.valid?
  end

  test "com scale: 4 o texto brasileiro é gravado, lido e consultado" do
    precise = Class.new(Entry) do
      self.table_name = "entries"
      attribute :amount, :br_currency, scale: 4
      def self.name
        "PreciseEntry"
      end
    end

    entry = precise.create!(amount: "R$ 10,1234")

    assert_equal BigDecimal("10.1234"), precise.find(entry.id).amount
    assert_equal [entry.id], precise.where(amount: "10,1234").pluck(:id)
    refute precise.new(amount: "1,00001").valid?
  end

  test "10 mil documentos gerados fora da gem são aceitos e os adulterados, rejeitados" do
    random = Random.new(2026)
    10_000.times do |i|
      cpf = FakeDocuments.cpf(random)
      cnpj = FakeDocuments.cnpj(random, alphanumeric: i.odd?)
      assert RailsBr::CPF.valid?(cpf), cpf
      assert RailsBr::CNPJ.valid?(cnpj), cnpj
      refute RailsBr::CPF.valid?(cpf[0...-1] + ((cpf[-1].to_i + 1) % 10).to_s), cpf
      refute RailsBr::CNPJ.valid?(cnpj[0...-1] + ((cnpj[-1].to_i + 1) % 10).to_s), cnpj
    end
  end
end
