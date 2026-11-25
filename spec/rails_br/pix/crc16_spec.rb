# frozen_string_literal: true

RSpec.describe RailsBr::Pix::CRC16 do
  describe ".checksum" do
    it "calcula o valor de verificação padrão do CRC-16/CCITT-FALSE" do
      expect(described_class.checksum("123456789")).to eq("29B1")
    end

    it "devolve o valor inicial para uma entrada vazia" do
      expect(described_class.checksum("")).to eq("FFFF")
    end

    it "devolve sempre 4 dígitos hexadecimais maiúsculos" do
      random = Random.new(42)

      200.times do
        data = Array.new(random.rand(1..60)) { random.rand(32..126).chr }.join
        expect(described_class.checksum(data)).to match(/\A\h{4}\z/).and eq(described_class.checksum(data).upcase)
      end
    end

    it "depende da ordem dos bytes" do
      expect(described_class.checksum("ab")).not_to eq(described_class.checksum("ba"))
    end

    # Os payloads abaixo são os exemplos dos manuais oficiais do Banco Central
    # (sem os 4 últimos caracteres, que são o próprio CRC).
    {
      "QR Code estático (Manual de Padrões do Pix, 2.6.3)" => [
        "00020126580014br.gov.bcb.pix0136123e4567-e12b-12d1-a456-4266554400005204000053039865802BR" \
        "5913Fulano de Tal6008BRASILIA62070503***6304", "1D3D"
      ],
      "QR Code dinâmico (Manual de Padrões do Pix)" => [
        "00020101021226700014br.gov.bcb.pix2548pix.example.com/8b3da2f39a4140d1a91abd93113bd441" \
        "5204000053039865802BR5913Fulano de Tal6008BRASILIA62070503***6304", "64E4"
      ],
      "Manual do BR Code v2.0.0" => [
        "00020104141234567890123426580014BR.GOV.BCB.PIX0136123e4567-e12b-12d1-a456-426655440000" \
        "27300012BR.COM.OUTRO011001234567895204000053039865406123.455802BR5917NOME DO RECEBEDOR" \
        "6008BRASILIA61087007490062190515RP12345678-201980390012BR.COM.OUTRO01190123.ABCD.3456.WXYZ6304", "AD38"
      ]
    }.each do |description, (data, expected)|
      it "reproduz o CRC oficial do exemplo: #{description}" do
        expect(described_class.checksum(data)).to eq(expected)
      end
    end
  end
end
