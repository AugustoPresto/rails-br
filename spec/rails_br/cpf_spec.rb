# frozen_string_literal: true

RSpec.describe RailsBr::CPF do
  describe ".valid?" do
    valid = ["111.444.777-35", "11144477735", "529.982.247-25", "  111.444.777-35  ", "111 444 777 35"]

    valid.each do |value|
      it "aceita #{value.inspect}" do
        expect(described_class.valid?(value)).to be(true)
      end
    end

    # Todos os valores abaixo têm dígitos verificadores corretos, exceto o caso indicado.
    {
      "nil" => nil,
      "string vazia" => "",
      "só espaços" => "   ",
      "dígito verificador errado" => "111.444.777-36",
      "primeiro dígito errado" => "111.444.777-45",
      "curto demais" => "111.444.777-3",
      "longo demais" => "111.444.777-355",
      "com letras" => "111.444.777-3A",
      "letras no meio" => "abc.444.777-35",
      "dígitos Unicode" => "１１１４４４７７７３５",
      "separador inesperado" => "111/444/777/35",
      "inteiro" => 11_144_477_735.5
    }.each do |description, value|
      it "rejeita #{description}" do
        expect(described_class.valid?(value)).to be(false)
      end
    end

    (0..9).each do |digit|
      it "rejeita a sequência repetida #{digit * 11}" do
        expect(described_class.valid?(digit.to_s * 11)).to be(false)
      end
    end

    it "aceita um inteiro que, convertido, forma um CPF válido" do
      expect(described_class.valid?(11_144_477_735)).to be(true)
    end

    it "aceita zeros à esquerda quando o CPF vem como string" do
      expect(described_class.valid?("012.345.678-90")).to be(true)
      expect(described_class.valid?("000.000.001-91")).to be(true)
    end

    it "não completa zeros perdidos: o inteiro 191 não é o CPF 000.000.001-91" do
      expect(described_class.valid?(191)).to be(false)
    end
  end

  describe ".parse!" do
    it "devolve o CPF quando válido" do
      expect(described_class.parse!("111.444.777-35")).to eq(described_class.new("11144477735"))
    end

    it "levanta InvalidValueError quando inválido" do
      expect { described_class.parse!("123") }
        .to raise_error(RailsBr::InvalidValueError, /CPF inválido: "123"/)
    end
  end

  describe "#digits e #to_s" do
    subject(:cpf) { described_class.new("111.444.777-35") }

    it "remove a máscara" do
      expect(cpf.digits).to eq("11144477735")
      expect(cpf.to_s).to eq("11144477735")
    end

    it "é imutável" do
      expect(cpf).to be_frozen
      expect(cpf.digits).to be_frozen
    end
  end

  describe "#formatted" do
    it "aplica a máscara em um CPF válido" do
      expect(described_class.new("11144477735").formatted).to eq("111.444.777-35")
    end

    it "devolve nil para um CPF inválido" do
      expect(described_class.new("11144477736").formatted).to be_nil
      expect(described_class.new(nil).formatted).to be_nil
    end
  end

  describe "igualdade" do
    it "compara pelos dígitos, ignorando a máscara" do
      expect(described_class.new("111.444.777-35")).to eq(described_class.new("11144477735"))
    end

    it "funciona como chave de Hash" do
      hash = { described_class.new("111.444.777-35") => :ok }
      expect(hash[described_class.new("11144477735")]).to eq(:ok)
    end

    it "não é igual a uma String" do
      expect(described_class.new("11144477735")).not_to eq("11144477735")
    end
  end
end
