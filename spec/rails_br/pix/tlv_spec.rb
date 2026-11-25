# frozen_string_literal: true

RSpec.describe RailsBr::Pix::TLV do
  describe ".parse" do
    it "lê objetos em sequência" do
      expect(described_class.parse("000201010211")).to eq([%w[00 01], %w[01 11]])
    end

    it "devolve uma lista vazia para uma string vazia" do
      expect(described_class.parse("")).to eq([])
    end

    it "mantém objetos aninhados como texto, para leitura em outro nível" do
      pairs = described_class.parse("26180014br.gov.bcb.pix")

      expect(pairs).to eq([["26", "0014br.gov.bcb.pix"]])
      expect(described_class.parse(pairs.first.last)).to eq([["00", "br.gov.bcb.pix"]])
    end

    it "aceita valores com tamanho zero" do
      expect(described_class.parse("5900")).to eq([["59", ""]])
    end

    it "conta o tamanho em caracteres, não em bytes" do
      expect(described_class.parse("5904João")).to eq([%w[59 João]])
    end

    {
      "ID não numérico" => "ab0201",
      "tamanho não numérico" => "00xx01",
      "cabeçalho incompleto" => "000",
      "valor truncado" => "000301",
      "dígitos Unicode" => "０００２０１"
    }.each do |description, input|
      it "levanta InvalidValueError para #{description}" do
        expect { described_class.parse(input) }.to raise_error(RailsBr::InvalidValueError)
      end
    end

    it "informa a posição do erro" do
      expect { described_class.parse("000201ab") }
        .to raise_error(RailsBr::InvalidValueError, /posição 6/)
    end
  end
end
