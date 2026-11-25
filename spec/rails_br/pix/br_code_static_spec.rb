# frozen_string_literal: true

RSpec.describe RailsBr::Pix::BRCode, ".static" do
  let(:evp) { PixPayloads::EVP_KEY }
  let(:base) { { key: evp, name: "Fulano de Tal", city: "BRASILIA" } }

  def with_crc(body)
    "#{body}6304#{RailsBr::Pix::CRC16.checksum("#{body}6304")}"
  end

  describe "payload gerado" do
    it "reproduz byte a byte o exemplo oficial do Manual de Padrões do Pix" do
      expect(described_class.static(**base).to_s).to eq(PixPayloads::STATIC)
    end

    it "inclui o valor com duas casas decimais" do
      expected = with_crc(
        "00020126580014br.gov.bcb.pix0136#{evp}5204000053039865406100.505802BR" \
        "5913Fulano de Tal6008BRASILIA62070503***"
      )

      expect(described_class.static(**base, amount: BigDecimal("100.50")).to_s).to eq(expected)
    end

    it "inclui o txid" do
      payload = described_class.static(**base, txid: "PEDIDO42").to_s

      expect(payload).to include("62120508PEDIDO42")
    end

    it "inclui a infoAdicional no template do Pix" do
      payload = described_class.static(**base, info: "Pedido 42").to_s

      expect(payload).to include("0209Pedido 42")
    end

    it "gera um BR Code válido e estático", :aggregate_failures do
      code = described_class.static(**base, amount: "10.5", txid: "ABC123", info: "Pedido 42")

      expect(code).to be_valid
      expect(code).to be_static
      expect([code.name, code.city, code.amount, code.txid, code.info])
        .to eq(["Fulano de Tal", "BRASILIA", BigDecimal("10.5"), "ABC123", "Pedido 42"])
    end

    it "aceita a chave como Pix::Key" do
      key = RailsBr::Pix::Key.new("pix@bcb.gov.br")

      expect(described_class.static(**base, key: key).key).to eq(key)
    end

    it "aceita chaves de todos os tipos" do
      %w[11144477735 12ABC34501DE35 +5561912345678 pix@bcb.gov.br].each do |key|
        expect(described_class.static(**base, key: key)).to be_valid
      end
    end
  end

  describe "valor" do
    {
      "BigDecimal" => [BigDecimal("100.5"), "100.50"],
      "BigDecimal inteiro" => [BigDecimal("7"), "7.00"],
      "Integer" => [100, "100.00"],
      "String com decimais" => ["10.5", "10.50"],
      "String inteira" => ["42", "42.00"],
      "String com espaços" => [" 1.99 ", "1.99"],
      "um centavo" => [BigDecimal("0.01"), "0.01"],
      "o máximo de 13 caracteres" => [BigDecimal("9999999999.99"), "9999999999.99"]
    }.each do |description, (amount, formatted)|
      it "formata #{description} como #{formatted}" do
        object = "54#{format('%02d', formatted.length)}#{formatted}"

        expect(described_class.static(**base, amount: amount).to_s).to include(object)
      end
    end

    {
      "Float" => 10.5,
      "zero" => 0,
      "negativo" => BigDecimal("-1"),
      "com 3 casas decimais" => BigDecimal("1.234"),
      "acima do máximo" => BigDecimal("10000000000"),
      "NaN" => BigDecimal("NaN"),
      "String com vírgula" => "10,50",
      "String não numérica" => "abc",
      "Rational" => Rational(1, 3),
      "símbolo" => :dez
    }.each do |description, amount|
      it "rejeita #{description}" do
        expect { described_class.static(**base, amount: amount) }.to raise_error(RailsBr::InvalidValueError)
      end
    end

    it "explica que Float não é aceito" do
      expect { described_class.static(**base, amount: 10.5) }
        .to raise_error(RailsBr::InvalidValueError, /nunca Float/)
    end
  end

  describe "nome e cidade" do
    it "remove acentos" do
      code = described_class.static(**base, name: "João da Silva Çã", city: "São Paulo")

      expect([code.name, code.city]).to eq(["Joao da Silva Ca", "Sao Paulo"])
    end

    it "remove espaços nas pontas" do
      expect(described_class.static(**base, name: "  Fulano  ").name).to eq("Fulano")
    end

    it "aceita os tamanhos máximos (25 e 15)" do
      code = described_class.static(**base, name: "N" * 25, city: "C" * 15)

      expect(code).to be_valid
    end

    {
      "nome vazio" => { name: "" },
      "nome nil" => { name: nil },
      "nome só com espaços" => { name: "   " },
      "nome com 26 caracteres" => { name: "N" * 26 },
      "nome com caracteres não suportados" => { name: "日本" },
      "nome com ß, que não tem forma decomposta" => { name: "Straße" },
      "nome com quebra de linha" => { name: "Fulano\nTal" },
      "cidade vazia" => { city: "" },
      "cidade com 16 caracteres" => { city: "C" * 16 }
    }.each do |description, overrides|
      it "rejeita #{description}" do
        expect { described_class.static(**base, **overrides) }.to raise_error(RailsBr::InvalidValueError)
      end
    end
  end

  describe "chave, txid e infoAdicional" do
    it "rejeita uma chave Pix inválida" do
      expect { described_class.static(**base, key: "111.444.777-35") }
        .to raise_error(RailsBr::InvalidValueError, /chave Pix inválida/)
    end

    {
      "com hífen" => "ab-cd",
      "com espaço" => "ab cd",
      "com acento" => "pedído",
      "com 26 caracteres" => "a" * 26,
      "vazio" => ""
    }.each do |description, txid|
      it "rejeita txid #{description}" do
        expect { described_class.static(**base, txid: txid) }.to raise_error(RailsBr::InvalidValueError, /txid/)
      end
    end

    it "aceita txid com 25 caracteres" do
      expect(described_class.static(**base, txid: "a" * 25).txid).to eq("a" * 25)
    end

    it "aceita a maior infoAdicional que cabe no template de 99 caracteres (37, com chave de 36)" do
      expect(described_class.static(**base, info: "i" * 37)).to be_valid
    end

    it "rejeita infoAdicional que estoura o template de 99 caracteres" do
      expect { described_class.static(**base, info: "i" * 38) }
        .to raise_error(RailsBr::InvalidValueError, /objeto 26 excede 99/)
    end

    it "rejeita infoAdicional vazia" do
      expect { described_class.static(**base, info: "") }.to raise_error(RailsBr::InvalidValueError, /infoAdicional/)
    end
  end

  describe "argumentos obrigatórios" do
    it "exige key, name e city" do
      expect { described_class.static(name: "A", city: "B") }.to raise_error(ArgumentError, /key/)
      expect { described_class.static(key: "pix@bcb.gov.br", city: "B") }.to raise_error(ArgumentError, /name/)
    end
  end

  describe "ida e volta" do
    let(:alphanumeric) { [*"a".."z", *"A".."Z", *"0".."9"] }
    let(:keys) { ["11144477735", "12ABC34501DE35", "+5561912345678", "pix@bcb.gov.br", evp] }

    def random_text(random, max)
      Array.new(random.rand(1..max)) { alphanumeric.sample(random: random) }.join
    end

    def random_fields(random)
      {
        key: keys.sample(random: random),
        name: random_text(random, 25),
        city: random_text(random, 15),
        amount: random.rand(2) == 1 ? BigDecimal(random.rand(1..99_999_999)) / 100 : nil,
        txid: random.rand(2) == 1 ? random_text(random, 25) : nil
      }
    end

    it "gera BR Codes que o parser lê de volta com os mesmos dados (200 casos aleatórios)" do
      random = Random.new(2026)

      200.times do
        fields = random_fields(random)
        code = described_class.parse!(described_class.static(**fields).to_s)

        expect([code.key.to_s, code.name, code.city, code.amount, code.txid]).to eq(fields.values)
      end
    end
  end
end
