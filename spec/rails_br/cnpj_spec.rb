# frozen_string_literal: true

RSpec.describe RailsBr::CNPJ do
  # Implementação de referência independente, com a tabela de pesos explícita
  # (esquerda para a direita), como descrita nas fontes da Receita Federal.
  # Serve de oráculo para comparar com o cálculo cíclico da gem.
  def reference_check_digits(base)
    weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]
    weights2 = [6] + weights1
    dv = lambda do |chars, weights|
      sum = chars.each_char.zip(weights).sum { |char, weight| (char.ord - 48) * weight }
      sum % 11 < 2 ? 0 : 11 - (sum % 11)
    end
    first = dv.call(base, weights1)
    "#{first}#{dv.call("#{base}#{first}", weights2)}"
  end

  describe ".valid?" do
    {
      "numérico com máscara" => "11.222.333/0001-81",
      "numérico sem máscara" => "11222333000181",
      "numérico, outro exemplo" => "11.444.777/0001-61",
      "numérico com raiz de zeros" => "00.000.000/0001-91",
      "alfanumérico (exemplo oficial da Receita)" => "12.ABC.345/01DE-35",
      "alfanumérico sem máscara" => "12ABC34501DE35",
      "alfanumérico em minúsculas" => "12.abc.345/01de-35",
      "com espaços nas pontas" => "  12.ABC.345/01DE-35  "
    }.each do |description, value|
      it "aceita #{description}" do
        expect(described_class.valid?(value)).to be(true)
      end
    end

    {
      "nil" => nil,
      "string vazia" => "",
      "dígito verificador errado (numérico)" => "11.222.333/0001-82",
      "dígito verificador errado (alfanumérico)" => "12.ABC.345/01DE-36",
      "primeiro dígito errado" => "12.ABC.345/01DE-05",
      "curto demais" => "11.222.333/0001-8",
      "longo demais" => "11.222.333/0001-811",
      "letras nos dígitos verificadores" => "12.ABC.345/01DE-3A",
      "letra minúscula acentuada" => "12.ÁBC.345/01DE-35",
      "símbolo entre '9' e 'A' (ASCII 58 a 64)" => "12.:BC.345/01DE-35",
      "dígitos Unicode" => "１１２２２３３３０００１８１",
      "separador inesperado" => "11,222,333,0001,81",
      "ß não vira SS" => "12.ABß.345/01DE-35"
    }.each do |description, value|
      it "rejeita #{description}" do
        expect(described_class.valid?(value)).to be(false)
      end
    end

    it "rejeita sequências repetidas, como 00.000.000/0000-00 e 11.111.111/1111-11" do
      ("0".."9").each do |digit|
        expect(described_class.valid?(digit * 14)).to be(false)
      end
    end

    it "coincide com a implementação de referência em 500 CNPJs alfanuméricos aleatórios" do
      random = Random.new(2026)
      alphabet = [*"0".."9", *"A".."Z"]

      500.times do
        base = Array.new(12) { alphabet[random.rand(alphabet.length)] }.join
        next if base.squeeze.length == 1

        cnpj = "#{base}#{reference_check_digits(base)}"
        expect(described_class.valid?(cnpj)).to be(true), "esperava #{cnpj} válido"
      end
    end

    it "rejeita qualquer alteração de um dígito verificador em 200 CNPJs aleatórios" do
      random = Random.new(7)
      alphabet = [*"0".."9", *"A".."Z"]

      200.times do
        base = Array.new(12) { alphabet[random.rand(alphabet.length)] }.join
        dvs = reference_check_digits(base)
        wrong = "#{(dvs[0].to_i + 1) % 10}#{dvs[1]}"
        expect(described_class.valid?("#{base}#{wrong}")).to be(false)
      end
    end
  end

  describe ".parse!" do
    it "devolve o CNPJ quando válido" do
      expect(described_class.parse!("12.abc.345/01de-35").to_s).to eq("12ABC34501DE35")
    end

    it "levanta InvalidValueError quando inválido" do
      expect { described_class.parse!("123") }
        .to raise_error(RailsBr::InvalidValueError, /CNPJ inválido: "123"/)
    end
  end

  describe "#alphanumeric?" do
    it "é verdadeiro quando há letras na raiz ou na ordem" do
      expect(described_class.new("12.ABC.345/01DE-35")).to be_alphanumeric
    end

    it "é falso para o CNPJ numérico" do
      expect(described_class.new("11.222.333/0001-81")).not_to be_alphanumeric
    end
  end

  describe "#value e #to_s" do
    subject(:cnpj) { described_class.new("12.abc.345/01de-35") }

    it "remove a máscara e converte para maiúsculas" do
      expect(cnpj.value).to eq("12ABC34501DE35")
      expect(cnpj.to_s).to eq("12ABC34501DE35")
    end

    it "é imutável" do
      expect(cnpj).to be_frozen
      expect(cnpj.value).to be_frozen
    end
  end

  describe "#formatted" do
    it "aplica a máscara em um CNPJ numérico" do
      expect(described_class.new("11222333000181").formatted).to eq("11.222.333/0001-81")
    end

    it "aplica a máscara em um CNPJ alfanumérico" do
      expect(described_class.new("12abc34501de35").formatted).to eq("12.ABC.345/01DE-35")
    end

    it "devolve nil para um CNPJ inválido" do
      expect(described_class.new("11222333000182").formatted).to be_nil
      expect(described_class.new(nil).formatted).to be_nil
    end
  end

  describe "igualdade" do
    it "ignora máscara e caixa" do
      expect(described_class.new("12.abc.345/01de-35")).to eq(described_class.new("12ABC34501DE35"))
    end

    it "funciona como chave de Hash" do
      hash = { described_class.new("11.222.333/0001-81") => :ok }
      expect(hash[described_class.new("11222333000181")]).to eq(:ok)
    end

    it "não é igual a um CPF com o mesmo valor, nem a uma String" do
      expect(described_class.new("11222333000181")).not_to eq("11222333000181")
      expect(described_class.new("11222333000181")).not_to eq(RailsBr::CPF.new("11222333000181"))
    end
  end
end
