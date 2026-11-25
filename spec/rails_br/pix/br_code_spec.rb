# frozen_string_literal: true

RSpec.describe RailsBr::Pix::BRCode do
  def tlv(id, value)
    "#{id}#{format('%02d', value.length)}#{value}"
  end

  # Monta um payload válido (com CRC), permitindo trocar ou remover objetos.
  # Valor `nil` remove o objeto; as chaves são os IDs do nível raiz.
  def build(overrides = {})
    parts = {
      "00" => "01",
      "26" => pix_template(tlv("01", PixPayloads::EVP_KEY)),
      "52" => "0000", "53" => "986", "58" => "BR", "59" => "Fulano de Tal", "60" => "BRASILIA",
      "62" => tlv("05", "***")
    }.merge(overrides).compact

    with_crc(parts.sort.map { |id, value| tlv(id, value) }.join)
  end

  def with_crc(body)
    "#{body}6304#{RailsBr::Pix::CRC16.checksum("#{body}6304")}"
  end

  def pix_template(*extra)
    ([tlv("00", "br.gov.bcb.pix")] + extra).join
  end

  def error_for(payload)
    described_class.new(payload).error
  end

  describe "exemplos oficiais", :aggregate_failures do
    it "valida o QR Code estático" do
      code = described_class.new(PixPayloads::STATIC)

      expect(code).to be_valid
      expect(code).to be_static
      expect(code).not_to be_dynamic
      expect(code.key).to eq(RailsBr::Pix::Key.new(PixPayloads::EVP_KEY))
      expect(code.key.type).to eq(:evp)
    end

    it "lê os dados do QR Code estático" do
      code = described_class.new(PixPayloads::STATIC)

      expect([code.name, code.city, code.amount, code.txid, code.info, code.url])
        .to eq(["Fulano de Tal", "BRASILIA", nil, nil, nil, nil])
    end

    it "valida o QR Code dinâmico e lê a URL, sem protocolo" do
      code = described_class.new(PixPayloads::DYNAMIC)

      expect(code).to be_valid
      expect(code).to be_dynamic
      expect(code).not_to be_static
      expect(code.url).to eq("pix.example.com/8b3da2f39a4140d1a91abd93113bd441")
      expect(code.key).to be_nil
    end

    it "lê o valor como BigDecimal e ignora o template de recorrência" do
      code = described_class.new(PixPayloads::STATIC_WITH_AMOUNT)

      expect(code).to be_valid
      expect(code.amount).to eq(BigDecimal("100.50"))
      expect(code.amount).to be_a(BigDecimal)
    end

    it "valida o QR Code só de recorrência (sem chave nem URL de cobrança)" do
      code = described_class.new(PixPayloads::RECURRENCE_ONLY)

      expect(code).to be_valid
      expect(code).not_to be_static
      expect(code).not_to be_dynamic
    end

    it "valida o QR Code dinâmico com recorrência" do
      expect(described_class.valid?(PixPayloads::DYNAMIC_WITH_RECURRENCE)).to be(true)
    end

    it "rejeita o exemplo genérico do Manual do BR Code porque o txid tem hífen" do
      code = described_class.new(PixPayloads::BR_CODE_MANUAL)

      expect(code).not_to be_valid
      expect(code.error).to include('txid (62-05) inválido: "RP12345678-2019"')
    end
  end

  describe "tolerância na entrada" do
    it "ignora espaços e quebras de linha nas pontas" do
      expect(described_class.valid?("  #{PixPayloads::STATIC}\n")).to be(true)
    end

    it "aceita o CRC em minúsculas" do
      expect(described_class.valid?(PixPayloads::STATIC.sub("1D3D", "1d3d"))).to be(true)
    end

    it "aceita o GUI em maiúsculas (é case insensitive)" do
      template = tlv("00", "BR.GOV.BCB.PIX") + tlv("01", PixPayloads::EVP_KEY)

      expect(described_class.valid?(build("26" => template))).to be(true)
    end
  end

  describe "payloads malformados" do
    it "rejeita nil e string vazia" do
      expect(described_class.valid?(nil)).to be(false)
      expect(error_for("")).to eq("payload vazio")
    end

    {
      "CRC adulterado" => [->(p) { p.sub("1D3D", "1D3E") }, /CRC16 não confere \(esperado 1D3D\)/],
      "CRC malformado" => [->(p) { p.sub("1D3D", "ZZZZ") }, /CRC16 malformado/],
      "payload truncado" => [->(p) { p[0..-10] }, /truncado|malformado|último objeto/],
      "lixo no final" => [->(p) { "#{p}X" }, /malformado/],
      "TLV malformado" => [->(_) { "00ab" }, /malformado/]
    }.each do |description, (mutation, message)|
      it "rejeita #{description}" do
        error = error_for(mutation.call(PixPayloads::STATIC))

        expect(error).to match(message)
      end
    end

    it "rejeita quando o primeiro objeto não é o 00" do
      expect(error_for(with_crc("010211#{tlv('00', '01')}"))).to include("primeiro objeto deve ser 00")
    end

    it "rejeita quando o último objeto não é o 63" do
      expect(error_for("#{PixPayloads::STATIC}9901A")).to include("último objeto deve ser 63")
    end

    it "rejeita objetos repetidos no nível raiz" do
      body = PixPayloads::STATIC[0...-8] # sem o CRC

      expect(error_for(with_crc("#{body}5802BR"))).to include("objeto 58 repetido")
    end
  end

  describe "campos obrigatórios e formatos" do
    {
      "moeda diferente de BRL" => [{ "53" => "840" }, /moeda/],
      "país diferente de BR" => [{ "58" => "US" }, /país/],
      "sem o código de categoria" => [{ "52" => nil }, /categoria/],
      "categoria com letras" => [{ "52" => "ABCD" }, /categoria/],
      "sem o nome do recebedor" => [{ "59" => nil }, /nome do recebedor \(59\) ausente/],
      "nome com 26 caracteres" => [{ "59" => "A" * 26 }, /nome do recebedor.*1 a 25/],
      "sem a cidade" => [{ "60" => nil }, /cidade do recebedor \(60\) ausente/],
      "cidade com 16 caracteres" => [{ "60" => "B" * 16 }, /cidade do recebedor.*1 a 15/],
      "sem o template 62" => [{ "62" => nil }, /template 62 ausente/],
      "template 62 sem o txid" => [{ "62" => "0601x" }, /62-05\) ausente/],
      "txid com caractere inválido" => [{ "62" => "0505ab-cd" }, /txid.*inválido/],
      "txid com 26 caracteres" => [{ "62" => "0526#{'a' * 26}" }, /txid.*inválido/],
      "ponto de iniciação inválido" => [{ "01" => "13" }, /ponto de iniciação/],
      "valor com vírgula" => [{ "54" => "1,00" }, /valor \(54\) inválido/],
      "valor com 3 casas decimais" => [{ "54" => "1.234" }, /valor \(54\) inválido/],
      "valor negativo" => [{ "54" => "-1.00" }, /valor \(54\) inválido/],
      "valor com mais de 13 caracteres" => [{ "54" => "12345678901.00" }, /valor \(54\) inválido/]
    }.each do |description, (overrides, message)|
      it "rejeita #{description}" do
        expect(error_for(build(overrides))).to match(message)
      end
    end
  end

  describe "template do Pix (IDs 26 a 51)" do
    it "rejeita payload sem template do Pix" do
      other = tlv("00", "br.com.outro") + tlv("01", "abc")

      expect(error_for(build("26" => other))).to match(/template do Pix.*ausente/)
    end

    it "rejeita template sem chave nem URL" do
      expect(error_for(build("26" => pix_template))).to include("chave (01) ou a URL (25)")
    end

    it "rejeita template com chave e URL ao mesmo tempo" do
      template = pix_template(tlv("01", PixPayloads::EVP_KEY), tlv("25", "pix.example.com/abc"))

      expect(error_for(build("26" => template))).to include("não podem coexistir")
    end

    it "rejeita uma chave Pix inválida (e-mail em maiúsculas)" do
      template = pix_template(tlv("01", "Pix@bcb.gov.br"))

      expect(error_for(build("26" => template))).to include("chave Pix (26-01) inválida")
    end

    it "rejeita infoAdicional vazia" do
      template = pix_template(tlv("01", PixPayloads::EVP_KEY), "0200")

      expect(error_for(build("26" => template))).to include("infoAdicional")
    end

    it "aceita fss com 8 dígitos (ISPB do facilitador de saque)" do
      template = pix_template(tlv("01", PixPayloads::EVP_KEY), tlv("03", "12345678"))

      expect(described_class.valid?(build("26" => template))).to be(true)
    end

    it "rejeita fss que não tem 8 dígitos" do
      template = pix_template(tlv("01", PixPayloads::EVP_KEY), tlv("03", "123"))

      expect(error_for(build("26" => template))).to include("fss")
    end
  end

  describe "campos opcionais", :aggregate_failures do
    it "lê valor, txid e infoAdicional" do
      template = pix_template(tlv("01", PixPayloads::EVP_KEY), tlv("02", "Pedido 42"))
      code = described_class.new(build("26" => template, "54" => "10.5", "62" => tlv("05", "ABC123")))

      expect(code).to be_valid
      expect(code.amount).to eq(BigDecimal("10.5"))
      expect(code.txid).to eq("ABC123")
      expect(code.info).to eq("Pedido 42")
    end

    it "aceita o valor sem casas decimais" do
      expect(described_class.new(build("54" => "10")).amount).to eq(10)
    end

    it "aceita os pontos de iniciação 11 e 12" do
      expect(described_class.valid?(build("01" => "11"))).to be(true)
      expect(described_class.valid?(build("01" => "12"))).to be(true)
    end

    it "aceita um txid com 25 caracteres" do
      expect(described_class.new(build("62" => tlv("05", "a" * 25))).txid).to eq("a" * 25)
    end

    it "aceita objetos desconhecidos no nível raiz (como o CEP, ID 61)" do
      expect(described_class.valid?(build("61" => "70074900"))).to be(true)
    end
  end

  describe ".parse!" do
    it "devolve o BR Code quando válido" do
      expect(described_class.parse!(PixPayloads::STATIC)).to be_valid
    end

    it "levanta InvalidValueError com o motivo quando inválido" do
      expect { described_class.parse!(PixPayloads::STATIC.sub("1D3D", "0000")) }
        .to raise_error(RailsBr::InvalidValueError, /BR Code inválido: CRC16 não confere/)
    end
  end

  describe "payload inválido", :aggregate_failures do
    subject(:code) { described_class.new("lixo") }

    it "não expõe dados" do
      expect([code.key, code.url, code.name, code.city, code.amount, code.txid, code.info]).to all(be_nil)
      expect(code).not_to be_static
      expect(code).not_to be_dynamic
    end

    it "é imutável, como o BR Code válido" do
      expect(code).to be_frozen
      expect(described_class.new(PixPayloads::STATIC)).to be_frozen
    end
  end

  describe "igualdade" do
    it "compara pelo payload normalizado" do
      expect(described_class.new(" #{PixPayloads::STATIC}\n")).to eq(described_class.new(PixPayloads::STATIC))
    end
  end
end
