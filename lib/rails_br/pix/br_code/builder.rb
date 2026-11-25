# frozen_string_literal: true

require "bigdecimal"
require_relative "../../error"
require_relative "../crc16"
require_relative "../key"

module RailsBr
  module Pix
    class BRCode
      # Monta o payload de um BR Code **estático** do Pix, na ordem dos objetos
      # dos exemplos do Manual de Padrões para Iniciação do Pix (v2.10.0, 2.6.3).
      # Uso interno de {BRCode.static}.
      #
      # @api private
      class Builder
        GUI = "br.gov.bcb.pix"
        MAX_TEMPLATE_LENGTH = 99
        MAX_NAME_LENGTH = 25
        MAX_CITY_LENGTH = 15
        MAX_AMOUNT = BigDecimal("9999999999.99") # 13 caracteres, com o ponto
        TXID_FORMAT = /\A[a-zA-Z0-9]{1,25}\z/.freeze
        NO_TXID = "***"
        PRINTABLE_ASCII = /\A[\x20-\x7E]+\z/.freeze
        AMOUNT_STRING = /\A\d+(\.\d+)?\z/.freeze

        # @return [String] o payload, com o CRC16
        def self.call(**fields)
          new(**fields).call
        end

        def initialize(key:, name:, city:, amount: nil, txid: nil, info: nil)
          @key = pix_key(key)
          @name = text(name, MAX_NAME_LENGTH, "nome do recebedor")
          @city = text(city, MAX_CITY_LENGTH, "cidade do recebedor")
          @amount = amount && format_amount(amount)
          @txid = txid.nil? ? NO_TXID : check_txid(txid)
          @info = info && text(info, MAX_TEMPLATE_LENGTH, "infoAdicional")
        end

        def call
          body = [
            object("00", "01"), object("26", pix_template), object("52", "0000"), object("53", "986"),
            (object("54", @amount) if @amount), object("58", "BR"), object("59", @name), object("60", @city),
            object("62", object("05", @txid))
          ].compact.join

          "#{body}6304#{CRC16.checksum("#{body}6304")}"
        end

        private

        def check(condition, message)
          raise InvalidValueError, message unless condition
        end

        def object(id, value)
          check(value.length <= MAX_TEMPLATE_LENGTH, "objeto #{id} excede 99 caracteres")

          "#{id}#{format('%02d', value.length)}#{value}"
        end

        def pix_template
          [object("00", GUI), object("01", @key), (object("02", @info) if @info)].compact.join
        end

        def pix_key(value)
          key = Key.new(value)
          check(key.valid?, "chave Pix inválida: #{value.inspect}")

          key.to_s
        end

        # Remove acentos e exige ASCII imprimível: os tamanhos do BR Code são
        # contados em caracteres, e assim ficam iguais aos bytes.
        def text(value, max, label)
          plain = value.to_s.unicode_normalize(:nfd).gsub(/\p{Mn}/, "").strip
          check((1..max).cover?(plain.length), "#{label} deve ter de 1 a #{max} caracteres")
          check(plain.match?(PRINTABLE_ASCII), "#{label} tem caracteres não suportados: #{value.inspect}")

          plain
        end

        def check_txid(value)
          check(value.to_s.match?(TXID_FORMAT), "txid deve ter de 1 a 25 letras ou dígitos: #{value.inspect}")

          value.to_s
        end

        def format_amount(amount)
          value = decimal(amount)
          check(value.finite? && value.positive?, "valor deve ser maior que zero e finito: #{amount.inspect}")
          check(value.round(2) == value, "valor aceita no máximo 2 casas decimais: #{amount.inspect}")
          check(value <= MAX_AMOUNT, "valor excede #{MAX_AMOUNT.to_s('F')}: #{amount.inspect}")

          integer, fraction = value.to_s("F").split(".")
          "#{integer}.#{fraction.to_s.ljust(2, '0')}"
        end

        # Dinheiro nunca é Float: só BigDecimal, Integer ou String decimal.
        def decimal(amount)
          case amount
          when BigDecimal then amount
          when Integer then BigDecimal(amount)
          when String then parse_amount(amount.strip)
          else raise InvalidValueError, "valor deve ser BigDecimal, Integer ou String (nunca Float): #{amount.inspect}"
          end
        end

        def parse_amount(string)
          check(string.match?(AMOUNT_STRING), "valor inválido (use ponto decimal): #{string.inspect}")

          BigDecimal(string)
        end
      end
    end
  end
end
