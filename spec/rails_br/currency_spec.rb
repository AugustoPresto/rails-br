# frozen_string_literal: true

RSpec.describe RailsBr::Currency do
  describe ".parse" do
    {
      "R$ 1.234,56" => "1234.56",
      "R$1.234,56" => "1234.56",
      "1.234,56" => "1234.56",
      "1234,56" => "1234.56",
      "1.234" => "1234",
      "1.234.567,89" => "1234567.89",
      "0,05" => "0.05",
      "1,5" => "1.5",
      "42" => "42",
      "007" => "7",
      "R$ 0,00" => "0",
      "  R$ 10,00  " => "10",
      "R$ 1.000,00" => "1000",
      "R$ 1.000,00" => "1000",
      "-1.234" => "-1234",
      "-R$ 1,00" => "-1",
      "R$ -1,00" => "-1",
      "- R$ 1,00" => "-1",
      "999999999999999999,99" => "999999999999999999.99"
    }.each do |text, expected|
      it "lê #{text.inspect} como #{expected}" do
        expect(described_class.parse(text)).to eq(BigDecimal(expected))
      end
    end

    it "devolve BigDecimal" do
      expect(described_class.parse("1,50")).to be_a(BigDecimal)
    end

    it "não devolve zero negativo" do
      expect(described_class.parse("-0,00").to_s).to eq(BigDecimal("0").to_s)
    end

    {
      "string vazia" => "",
      "só espaços" => "   ",
      "só o símbolo" => "R$",
      "texto" => "abc",
      "formato americano" => "1234.56",
      "formato americano com milhar" => "1,234.56",
      "milhar mal agrupado" => "1.23,4",
      "grupo de milhar curto" => "12.34",
      "grupo de milhar longo" => "1.2345",
      "milhar começando com zero" => "0.123",
      "3 casas decimais" => "1,234",
      "vírgula sem centavos" => "1,",
      "sem parte inteira" => ",50",
      "duas vírgulas" => "1,2,3",
      "dois sinais" => "-R$ -1,00",
      "sinal duplicado" => "--1,00",
      "sinal positivo" => "+1,00",
      "sinal no fim" => "1,00-",
      "outra moeda" => "US$ 1,00",
      "símbolo no fim" => "1,00 R$",
      "símbolo em minúsculas" => "r$ 1,00",
      "texto depois do valor" => "1,00 reais",
      "espaço no meio do número" => "1 234,00",
      "quebra de linha seguida de texto" => "1,00\nabc",
      "dígitos Unicode" => "１２３"
    }.each do |description, text|
      it "devolve nil para #{description}" do
        expect(described_class.parse(text)).to be_nil
      end
    end

    [nil, 1.234, 10, BigDecimal("1"), :um, ["1,00"]].each do |value|
      it "devolve nil para um valor que não é String: #{value.inspect}" do
        expect(described_class.parse(value)).to be_nil
      end
    end

    it "devolve nil para bytes inválidos, sem levantar erro" do
      expect(described_class.parse("1,00\xFF".dup.force_encoding("UTF-8"))).to be_nil
    end

    it "devolve nil para uma codificação incompatível com ASCII" do
      expect(described_class.parse("1,00".encode("UTF-16LE"))).to be_nil
    end
  end

  describe ".parse!" do
    it "devolve o valor quando válido, inclusive zero" do
      expect(described_class.parse!("0,00")).to eq(0)
    end

    it "levanta InvalidValueError quando inválido" do
      expect { described_class.parse!("1234.56") }
        .to raise_error(RailsBr::InvalidValueError, /valor monetário inválido: "1234.56"/)
    end
  end

  describe ".format" do
    {
      "0" => "R$ 0,00",
      "0.05" => "R$ 0,05",
      "1.5" => "R$ 1,50",
      "999" => "R$ 999,00",
      "1000" => "R$ 1.000,00",
      "1234.5" => "R$ 1.234,50",
      "1234567.89" => "R$ 1.234.567,89",
      "-1" => "-R$ 1,00",
      "-1234.56" => "-R$ 1.234,56"
    }.each do |value, expected|
      it "formata #{value} como #{expected.inspect}" do
        expect(described_class.format(BigDecimal(value))).to eq(expected)
      end
    end

    it "aceita Integer" do
      expect(described_class.format(1500)).to eq("R$ 1.500,00")
    end

    it "pode omitir o símbolo" do
      expect(described_class.format(BigDecimal("-1234.5"), symbol: false)).to eq("-1.234,50")
    end

    it "formata o zero negativo sem sinal" do
      expect(described_class.format(BigDecimal("-0"))).to eq("R$ 0,00")
    end

    {
      "Float" => 1.5,
      "String" => "1,50",
      "nil" => nil,
      "Rational" => Rational(1, 3),
      "3 casas decimais" => BigDecimal("1.005"),
      "NaN" => BigDecimal("NaN"),
      "infinito" => BigDecimal("Infinity")
    }.each do |description, value|
      it "levanta InvalidValueError para #{description}" do
        expect { described_class.format(value) }.to raise_error(RailsBr::InvalidValueError)
      end
    end
  end

  it "lê de volta tudo o que formata (500 valores aleatórios)" do
    random = Random.new(2026)

    500.times do
      value = BigDecimal(random.rand(-10_000_000_000..10_000_000_000)) / 100

      expect(described_class.parse(described_class.format(value))).to eq(value)
    end
  end
end
