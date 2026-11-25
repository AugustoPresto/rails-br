# frozen_string_literal: true

require_relative "../document"

module RailsBr
  module Pix
    # BR Code do Pix, o texto do "Pix copia e cola" (e do QR Code), no padrão
    # EMV QRCPS-MPM. Lê e valida o payload: estrutura TLV, CRC16, campos
    # obrigatórios e regras do Pix.
    #
    # Aceita QR Codes estáticos (com chave), dinâmicos (com URL) e os que levam
    # parâmetros de recorrência. Espaços e quebras de linha nas pontas são
    # ignorados. Os tamanhos são contados em caracteres.
    #
    # @example
    #   code = RailsBr::Pix::BRCode.new(payload)
    #   code.valid?    # => true
    #   code.static?   # => true
    #   code.key.to_s  # => "123e4567-e12b-12d1-a456-426655440000"
    #   code.name      # => "Fulano de Tal"
    #   code.amount    # => nil (ou um BigDecimal)
    class BRCode < Document
      autoload :Parser, "rails_br/pix/br_code/parser"
      autoload :Builder, "rails_br/pix/br_code/builder"

      # Gera um BR Code **estático** (o "Pix copia e cola" de uma chave fixa).
      #
      # O nome e a cidade perdem os acentos e precisam ser ASCII imprimível
      # (nome até 25 caracteres, cidade até 15). O valor aceita `BigDecimal`,
      # `Integer` ou `String` com ponto decimal, nunca `Float`, com até 2 casas.
      # Sem `txid`, o payload leva `***`, que indica a ausência de identificador.
      #
      # @example
      #   code = RailsBr::Pix::BRCode.static(
      #     key: "123e4567-e12b-12d1-a456-426655440000",
      #     name: "Fulano de Tal", city: "Brasília", amount: BigDecimal("100.50"), txid: "PEDIDO42"
      #   )
      #   code.to_s    # => "00020126580014br.gov.bcb.pix0136..."
      #   code.valid?  # => true
      #
      # @param key [String, Pix::Key] a chave Pix do recebedor
      # @param name [String] nome do recebedor (1 a 25 caracteres)
      # @param city [String] cidade do recebedor (1 a 15 caracteres)
      # @param amount [BigDecimal, Integer, String, nil] valor; `nil` deixa o pagador informar
      # @param txid [String, nil] identificador da transação (1 a 25 letras ou dígitos)
      # @param info [String, nil] descrição livre mostrada ao pagador
      # @return [BRCode]
      # @raise [InvalidValueError] se algum dado for inválido
      def self.static(key:, name:, city:, amount: nil, txid: nil, info: nil)
        new(Builder.call(key: key, name: name, city: city, amount: amount, txid: txid, info: info))
      end

      # Como {.new}, mas levanta {InvalidValueError}, com o motivo, se for inválido.
      #
      # @param value [#to_s, nil]
      # @return [BRCode]
      # @raise [InvalidValueError]
      def self.parse!(value)
        code = new(value)
        raise InvalidValueError, "BR Code inválido: #{code.error}" unless code.valid?

        code
      end

      # @return [String, nil] o motivo de o payload ser inválido, ou `nil` se for válido
      attr_reader :error

      # @return [Boolean]
      def valid?
        error.nil?
      end

      # @return [Pix::Key, nil] a chave Pix (QR Code estático)
      def key
        fields[:key]
      end

      # @return [String, nil] a URL do payload (QR Code dinâmico), sem o protocolo
      def url
        fields[:url]
      end

      # @return [String, nil] nome do recebedor (ID 59)
      def name
        fields[:name]
      end

      # @return [String, nil] cidade do recebedor (ID 60)
      def city
        fields[:city]
      end

      # @return [BigDecimal, nil] o valor (ID 54), se informado
      def amount
        fields[:amount]
      end

      # @return [String, nil] o identificador da transação (62-05); `nil` quando o
      #   payload traz `***`, que indica que não há txid
      def txid
        fields[:txid]
      end

      # @return [String, nil] a descrição livre (26-02)
      def info
        fields[:info]
      end

      # @return [Boolean] se o payload é de um QR Code estático (tem chave Pix)
      def static?
        valid? && !key.nil?
      end

      # @return [Boolean] se o payload é de um QR Code dinâmico (tem URL)
      def dynamic?
        valid? && !url.nil?
      end

      private

      attr_reader :fields

      # Espaços e quebras de linha comuns ao copiar e colar são ignorados.
      def normalize(string)
        string.strip
      end

      def prepare
        result = Parser.call(value)
        @fields = result.fields.freeze
        @error = result.error&.freeze
      end
    end
  end
end
