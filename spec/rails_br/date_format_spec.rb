# frozen_string_literal: true

RSpec.describe RailsBr::DateFormat do
  describe ".parse" do
    {
      "31/12/2026" => [2026, 12, 31],
      "05/01/2026" => [2026, 1, 5],
      "5/1/2026" => [2026, 1, 5],
      "  05/01/2026  " => [2026, 1, 5],
      "05/01/2026 " => [2026, 1, 5],
      "29/02/2024" => [2024, 2, 29],
      "29/02/2000" => [2000, 2, 29],
      "01/01/0001" => [1, 1, 1],
      "31/12/9999" => [9999, 12, 31]
    }.each do |text, parts|
      it "lê #{text.inspect}" do
        expect(described_class.parse(text)).to eq(Date.new(*parts))
      end
    end

    it "lê no padrão brasileiro: dia antes do mês" do
      expect(described_class.parse("02/03/2026")).to eq(Date.new(2026, 3, 2))
    end

    {
      "29 de fevereiro em ano não bissexto" => "29/02/2025",
      "29 de fevereiro em século não bissexto" => "29/02/1900",
      "31 de abril" => "31/04/2026",
      "dia zero" => "00/01/2026",
      "mês zero" => "01/00/2026",
      "mês 13" => "01/13/2026",
      "dia 32" => "32/01/2026",
      "dias removidos na reforma gregoriana" => "10/10/1582",
      "ano zero" => "01/01/0000",
      "ano com 2 dígitos" => "31/12/26",
      "ano com 3 dígitos" => "31/12/026",
      "ano com 5 dígitos" => "31/12/12026",
      "formato ISO" => "2026-12-31",
      "separador hífen" => "31-12-2026",
      "separador ponto" => "31.12.2026",
      "sem separador" => "31122026",
      "sem ano" => "31/12",
      "com hora" => "31/12/2026 10:00",
      "texto sobrando" => "31/12/2026abc",
      "texto antes" => "data: 31/12/2026",
      "espaço no meio" => "31 /12/2026",
      "quebra de linha seguida de texto" => "31/12/2026\nabc",
      "sinal" => "-1/12/2026",
      "dígitos Unicode" => "３１/１２/２０２６",
      "string vazia" => "",
      "só espaços" => "   "
    }.each do |description, text|
      it "devolve nil para #{description}" do
        expect(described_class.parse(text)).to be_nil
      end
    end

    [nil, 31_122_026, Date.new(2026, 12, 31), :hoje, ["31/12/2026"]].each do |value|
      it "devolve nil para um valor que não é String: #{value.inspect}" do
        expect(described_class.parse(value)).to be_nil
      end
    end

    it "devolve nil para bytes inválidos ou codificação incompatível, sem levantar erro" do
      expect(described_class.parse("31/12/2026\xFF".dup.force_encoding("UTF-8"))).to be_nil
      expect(described_class.parse("31/12/2026".encode("UTF-16LE"))).to be_nil
    end
  end

  describe ".parse!" do
    it "devolve a data quando válida" do
      expect(described_class.parse!("31/12/2026")).to eq(Date.new(2026, 12, 31))
    end

    it "levanta InvalidValueError quando inválida" do
      expect { described_class.parse!("31/02/2026") }
        .to raise_error(RailsBr::InvalidValueError, %r{data inválida: "31/02/2026"})
    end
  end

  describe ".format" do
    it "completa dia, mês e ano com zeros" do
      expect(described_class.format(Date.new(2026, 1, 5))).to eq("05/01/2026")
      expect(described_class.format(Date.new(33, 4, 3))).to eq("03/04/0033")
    end

    it "usa só a data de um DateTime" do
      expect(described_class.format(DateTime.new(2026, 12, 31, 23, 59))).to eq("31/12/2026")
    end

    {
      "Time" => Time.utc(2026, 12, 31),
      "String" => "2026-12-31",
      "nil" => nil,
      "Integer" => 20_261_231,
      "ano zero" => Date.new(0, 1, 1),
      "ano negativo" => Date.new(-1, 1, 1),
      "ano com 5 dígitos" => Date.new(10_000, 1, 1)
    }.each do |description, value|
      it "levanta InvalidValueError para #{description}" do
        expect { described_class.format(value) }.to raise_error(RailsBr::InvalidValueError)
      end
    end
  end

  it "lê de volta tudo o que formata (500 datas aleatórias)" do
    random = Random.new(2026)
    range = Date.new(1, 1, 1).jd..Date.new(9999, 12, 31).jd

    500.times do
      date = Date.jd(random.rand(range))

      expect(described_class.parse(described_class.format(date))).to eq(date)
    end
  end
end
