# frozen_string_literal: true

RSpec.describe RailsBr::Pix::Key do
  # Exemplos de chaves de cada tipo. Os formatos de e-mail, telefone, CNPJ
  # alfanumérico e chave aleatória vêm do Manual de Padrões para Iniciação do
  # Pix (seção 2.5.1) e da especificação da API do DICT.
  valid_keys = {
    cpf: %w[11144477735 52998224725 01234567890],
    cnpj: %w[11222333000181 12ABC34501DE35 00000000000191],
    phone: ["+5561912345678", "+5510998765432", "+14155552671"],
    email: ["fulano_da_silva.recebedor@example.com", "pix@bcb.gov.br", "a@b", "x+tag@sub.dominio.com.br"],
    evp: %w[123e4567-e12b-12d1-a456-426655440000 00000000-0000-4000-8000-000000000000]
  }

  describe "#type e #valid?" do
    valid_keys.each do |type, keys|
      keys.each do |key|
        it "reconhece #{key.inspect} como #{type}" do
          expect(described_class.new(key).type).to eq(type)
          expect(described_class.valid?(key)).to be(true)
        end
      end
    end

    invalid_keys = {
      "nil" => nil,
      "string vazia" => "",
      "CPF com máscara" => "111.444.777-35",
      "CPF com dígito verificador errado" => "11144477736",
      "CPF com sequência repetida" => "11111111111",
      "CNPJ com máscara" => "11.222.333/0001-81",
      "CNPJ com dígito verificador errado" => "11222333000182",
      "CNPJ alfanumérico em minúsculas" => "12abc34501de35",
      "telefone sem o +" => "5561912345678",
      "telefone com máscara" => "(61) 91234-5678",
      "telefone começando com 0 após o +" => "+0561912345678",
      "telefone com mais de 15 dígitos" => "+1234567890123456",
      "telefone com 1 dígito só" => "+5",
      "e-mail em maiúsculas" => "Pix@bcb.gov.br",
      "e-mail sem arroba" => "pixbcb.gov.br",
      "e-mail sem domínio" => "pix@",
      "e-mail com espaço" => "pix @bcb.gov.br",
      "e-mail com 78 caracteres" => "#{'a' * 66}@example.com",
      "chave aleatória em maiúsculas" => "123E4567-E12B-12D1-A456-426655440000",
      "chave aleatória sem hífens" => "123e4567e12b12d1a456426655440000",
      "chave aleatória curta" => "123e4567-e12b-12d1-a456-42665544000",
      "chave aleatória com caractere fora de hex" => "123e4567-e12b-12d1-a456-42665544000g",
      "espaços nas pontas" => " pix@bcb.gov.br ",
      "quebra de linha no final" => "pix@bcb.gov.br\n",
      "dígitos Unicode" => "１１１４４４７７７３５"
    }

    invalid_keys.each do |description, key|
      it "rejeita #{description}" do
        expect(described_class.new(key).type).to be_nil
        expect(described_class.valid?(key)).to be(false)
      end
    end

    it "aceita e-mail com exatamente 77 caracteres" do
      email = "#{'a' * 65}@example.com"

      expect(email.length).to eq(77)
      expect(described_class.new(email).type).to eq(:email)
    end

    it "classifica 11 dígitos válidos como CPF, nunca como telefone" do
      expect(described_class.type_of("11144477735")).to eq(:cpf)
    end
  end

  describe ".type_of" do
    it "devolve o tipo ou nil" do
      expect(described_class.type_of("pix@bcb.gov.br")).to eq(:email)
      expect(described_class.type_of("lixo")).to be_nil
    end
  end

  describe ".parse!" do
    it "devolve a chave quando válida" do
      expect(described_class.parse!("pix@bcb.gov.br").to_s).to eq("pix@bcb.gov.br")
    end

    it "levanta InvalidValueError quando inválida" do
      expect { described_class.parse!("111.444.777-35") }
        .to raise_error(RailsBr::InvalidValueError, /Chave Pix inválida: "111.444.777-35"/)
    end
  end

  describe "#value e #to_s" do
    subject(:key) { described_class.new("+5561912345678") }

    it "preserva a chave exatamente como recebida" do
      expect(key.value).to eq("+5561912345678")
      expect(key.to_s).to eq("+5561912345678")
    end

    it "é imutável" do
      expect(key).to be_frozen
      expect(key.value).to be_frozen
    end
  end

  describe "igualdade" do
    it "compara pelo valor" do
      original = described_class.new("pix@bcb.gov.br")

      expect(original).to eq(described_class.new(+"pix@bcb.gov.br"))
      expect(original).not_to eq(described_class.new("outro@bcb.gov.br"))
    end

    it "não é igual a uma String" do
      expect(described_class.new("pix@bcb.gov.br")).not_to eq("pix@bcb.gov.br")
    end
  end
end
