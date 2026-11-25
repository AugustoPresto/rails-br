# frozen_string_literal: true

module RailsBr
  # Helpers do Pix (Banco Central do Brasil).
  module Pix
    autoload :Key, "rails_br/pix/key"
    autoload :CRC16, "rails_br/pix/crc16"
    autoload :TLV, "rails_br/pix/tlv"
    autoload :BRCode, "rails_br/pix/br_code"
  end
end
