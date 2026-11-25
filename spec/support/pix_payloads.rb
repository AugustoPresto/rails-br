# frozen_string_literal: true

# Exemplos oficiais do Manual de Padrões para Iniciação do Pix (v2.10.0) e do
# Manual do BR Code (v2.0.0), do Banco Central. O CRC de cada um foi conferido
# com {RailsBr::Pix::CRC16}.
module PixPayloads
  EVP_KEY = "123e4567-e12b-12d1-a456-426655440000"

  STATIC = "00020126580014br.gov.bcb.pix0136123e4567-e12b-12d1-a456-4266554400005204000053039865802BR" \
           "5913Fulano de Tal6008BRASILIA62070503***63041D3D"

  DYNAMIC = "00020101021226700014br.gov.bcb.pix2548pix.example.com/8b3da2f39a4140d1a91abd93113bd441" \
            "5204000053039865802BR5913Fulano de Tal6008BRASILIA62070503***630464E4"

  STATIC_WITH_AMOUNT = "00020126580014br.gov.bcb.pix0136123e4567-e12b-12d1-a456-4266554400005204000053039865406" \
                       "100.505802BR5913Fulano de Tal6008BRASILIA62070503***80740014br.gov.bcb.pix2552pix." \
                       "example.com/rec/2353c790eefb11eaadc10242ac12000263042875"

  RECURRENCE_ONLY = "00020126180014br.gov.bcb.pix5204000053039865802BR5913Fulano de Tal6008BRASILIA62070503***" \
                    "80740014br.gov.bcb.pix2552pix.example.com/rec/2353c790eefb11eaadc10242ac1200026304F2DA"

  DYNAMIC_WITH_RECURRENCE = "00020101021226700014br.gov.bcb.pix2548pix.example.com/8b3da2f39a4140d1a91abd93113bd441" \
                            "5204000053039865802BR5913Fulano de Tal6008BRASILIA62070503***80740014br.gov.bcb.pix" \
                            "2552pix.example.com/rec/2353c790eefb11eaadc10242ac1200026304FB42"

  # Exemplo genérico do Manual do BR Code; o txid tem hífen, que o Pix não admite.
  BR_CODE_MANUAL = "00020104141234567890123426580014BR.GOV.BCB.PIX0136123e4567-e12b-12d1-a456-426655440000" \
                   "27300012BR.COM.OUTRO011001234567895204000053039865406123.455802BR5917NOME DO RECEBEDOR" \
                   "6008BRASILIA61087007490062190515RP12345678-201980390012BR.COM.OUTRO01190123.ABCD.3456." \
                   "WXYZ6304AD38"
end
