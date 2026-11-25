# frozen_string_literal: true

require_relative "../../error"
require_relative "../tlv"
require_relative "../key"

module RailsBr
  module Pix
    class BRCode
      # Lê o template do Pix dentro do BR Code: o objeto de ID 26 a 51 cujo GUI é
      # `br.gov.bcb.pix` (Manual de Padrões para Iniciação do Pix, seções 2.5 e
      # 2.6). Uso interno de {Parser}.
      #
      # @api private
      class PixTemplate
        GUI = "br.gov.bcb.pix"
        MERCHANT_ACCOUNT_IDS = ("26".."51").to_a.freeze
        UNRESERVED_IDS = ("80".."99").to_a.freeze
        FSS_FORMAT = /\A\d{8}\z/.freeze
        MAX_INFO_LENGTH = 72

        # @param root [Hash{String => String}] os objetos do nível raiz do BR Code
        # @return [Hash] `:key` (Pix::Key ou nil), `:url`, `:info` e `:fss`
        # @raise [InvalidValueError]
        def self.call(root)
          new(root).call
        end

        def initialize(root)
          @root = root
        end

        def call
          template = find_template
          key = template["01"]
          url = template["25"]
          check_payee_data(key, url)

          { key: key && pix_key(key), url: url, info: info(template["02"]), fss: fss(template["03"]) }
        end

        private

        attr_reader :root

        def find_template
          MERCHANT_ACCOUNT_IDS.each do |id|
            next unless root.key?(id)

            template = TLV.parse(root[id]).to_h
            return template if pix_gui?(template)
          end
          raise InvalidValueError, "template do Pix (GUI #{GUI}) ausente nos objetos 26 a 51"
        end

        # O GUI é case insensitive (Manual de Padrões do Pix, nota 10).
        def pix_gui?(template)
          template["00"]&.casecmp?(GUI) || false
        end

        def check_payee_data(key, url)
          raise InvalidValueError, "chave Pix (26-01) e URL (26-25) não podem coexistir" if key && url
          return if key || url || recurrence?

          raise InvalidValueError, "o template do Pix deve ter a chave (01) ou a URL (25)"
        end

        # QR Code só com parâmetros de recorrência: o template 26 traz apenas o
        # GUI, e um template 80 a 99 traz a URL da recorrência.
        def recurrence?
          UNRESERVED_IDS.any? { |id| root.key?(id) && pix_gui?(TLV.parse(root[id]).to_h) }
        end

        def pix_key(value)
          key = Key.new(value)
          raise InvalidValueError, "chave Pix (26-01) inválida: #{value.inspect}" unless key.valid?

          key
        end

        def info(value)
          return if value.nil?

          valid = (1..MAX_INFO_LENGTH).cover?(value.length)
          raise InvalidValueError, "infoAdicional (26-02) deve ter de 1 a #{MAX_INFO_LENGTH} caracteres" unless valid

          value
        end

        def fss(value)
          return if value.nil?
          raise InvalidValueError, "fss (26-03) deve ter 8 dígitos" unless value.match?(FSS_FORMAT)

          value
        end
      end
    end
  end
end
