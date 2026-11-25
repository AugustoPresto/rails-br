# frozen_string_literal: true

module RailsBr
  module Pix
    # CRC-16/CCITT-FALSE usado no campo 63 do BR Code: polinômio `0x1021`,
    # valor inicial `0xFFFF`, sem reflexão e sem XOR final (Manual do BR Code,
    # nota de rodapé 10, e EMV QRCPS-MPM, seção 4.7.3).
    #
    # @example
    #   RailsBr::Pix::CRC16.checksum("123456789") # => "29B1"
    module CRC16
      # Polinômio gerador (0x1021).
      POLYNOMIAL = 0x1021
      # Valor inicial do registrador (0xFFFF).
      INITIAL_VALUE = 0xFFFF
      # Máscara de 16 bits.
      MASK = 0xFFFF
      # Bit mais significativo do registrador.
      TOP_BIT = 0x8000

      # @param data [String] os bytes sobre os quais calcular o CRC
      # @return [String] 4 dígitos hexadecimais maiúsculos, com zeros à esquerda
      def self.checksum(data)
        crc = data.each_byte.reduce(INITIAL_VALUE) { |acc, byte| process_byte(acc, byte) }
        format("%04X", crc)
      end

      def self.process_byte(crc, byte)
        crc ^= byte << 8
        8.times do
          crc = crc.anybits?(TOP_BIT) ? ((crc << 1) ^ POLYNOMIAL) & MASK : (crc << 1) & MASK
        end
        crc
      end
      private_class_method :process_byte
    end
  end
end
