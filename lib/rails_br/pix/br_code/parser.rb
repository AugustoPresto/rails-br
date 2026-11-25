# frozen_string_literal: true

require "bigdecimal"
require_relative "../../error"
require_relative "../crc16"
require_relative "../tlv"
require_relative "pix_template"

module RailsBr
  module Pix
    class BRCode
      # Lê e valida um payload do BR Code do Pix ("Pix copia e cola") conforme o
      # Manual do BR Code (v2.0.0) e o Manual de Padrões para Iniciação do Pix
      # (v2.10.0). Uso interno de {BRCode}.
      #
      # @api private
      class Parser
        Result = Struct.new(:fields, :error, keyword_init: true)

        PAYLOAD_FORMAT = "01"
        CURRENCY_BRL = "986"
        COUNTRY_BRAZIL = "BR"
        POINTS_OF_INITIATION = %w[11 12].freeze
        CRC_HEADER = "6304"
        CRC_FORMAT = /\A\h{4}\z/.freeze
        AMOUNT_FORMAT = /\A\d+(\.\d{1,2})?\z/.freeze
        TXID_FORMAT = /\A[a-zA-Z0-9]{1,25}\z/.freeze
        NO_TXID = "***"
        MCC_FORMAT = /\A\d{4}\z/.freeze
        MAX_AMOUNT_LENGTH = 13
        MAX_NAME_LENGTH = 25
        MAX_CITY_LENGTH = 15

        # @param payload [String]
        # @return [Result]
        def self.call(payload)
          new(payload).call
        end

        def initialize(payload)
          @payload = payload
        end

        def call
          Result.new(fields: parse, error: nil)
        rescue InvalidValueError => e
          Result.new(fields: {}, error: e.message)
        end

        private

        attr_reader :payload

        def parse
          pairs = TLV.parse(payload)
          root = index_root(pairs)
          check_envelope(pairs, root)
          check_constants(root)

          PixTemplate.call(root).merge(
            name: text(root, "59", MAX_NAME_LENGTH, "nome do recebedor"),
            city: text(root, "60", MAX_CITY_LENGTH, "cidade do recebedor"),
            amount: amount(root),
            txid: txid(root)
          )
        end

        def index_root(pairs)
          ids = pairs.map(&:first)
          duplicated = ids.find { |id| ids.count(id) > 1 }
          raise InvalidValueError, "objeto #{duplicated} repetido" if duplicated

          pairs.to_h
        end

        def check_envelope(pairs, root)
          raise InvalidValueError, "payload vazio" if pairs.empty?
          raise InvalidValueError, "o primeiro objeto deve ser 00" unless pairs.first.first == "00"
          raise InvalidValueError, "o último objeto deve ser 63 (CRC16)" unless pairs.last.first == "63"

          check_crc(root.fetch("63"))
        end

        def check_crc(crc)
          well_formed = crc.match?(CRC_FORMAT) && payload.end_with?("#{CRC_HEADER}#{crc}")
          raise InvalidValueError, "CRC16 malformado" unless well_formed

          expected = CRC16.checksum(payload[0...-4])
          raise InvalidValueError, "CRC16 não confere (esperado #{expected})" unless crc.upcase == expected
        end

        def check_constants(root)
          require_value(root, "00", PAYLOAD_FORMAT, "indicador de formato")
          require_value(root, "53", CURRENCY_BRL, "moeda (BRL)")
          require_value(root, "58", COUNTRY_BRAZIL, "país")
          raise InvalidValueError, "código de categoria (52) inválido" unless root.fetch("52", "").match?(MCC_FORMAT)

          point = root["01"]
          raise InvalidValueError, "ponto de iniciação (01) inválido" if point && !POINTS_OF_INITIATION.include?(point)
        end

        def require_value(root, id, expected, label)
          raise InvalidValueError, "#{label} (#{id}) deve ser #{expected}" unless root[id] == expected
        end

        def text(root, id, max, label)
          value = root[id]
          raise InvalidValueError, "#{label} (#{id}) ausente" if value.nil?

          valid = (1..max).cover?(value.length)
          raise InvalidValueError, "#{label} (#{id}) deve ter de 1 a #{max} caracteres" unless valid

          value
        end

        def amount(root)
          value = root["54"]
          return if value.nil?

          valid = value.length <= MAX_AMOUNT_LENGTH && value.match?(AMOUNT_FORMAT)
          raise InvalidValueError, "valor (54) inválido: #{value.inspect}" unless valid

          BigDecimal(value)
        end

        def txid(root)
          template = TLV.parse(root.fetch("62") { raise InvalidValueError, "template 62 ausente" }).to_h
          label = template["05"]
          raise InvalidValueError, "identificador da transação (62-05) ausente" if label.nil?
          return if label == NO_TXID
          raise InvalidValueError, "txid (62-05) inválido: #{label.inspect}" unless label.match?(TXID_FORMAT)

          label
        end
      end
    end
  end
end
