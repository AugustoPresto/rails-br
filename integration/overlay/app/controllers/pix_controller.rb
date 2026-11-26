class PixController < ApplicationController
  def show
    code = RailsBr::Pix::BRCode.static(
      key: params[:key], name: params[:name], city: params[:city],
      amount: params[:amount] && RailsBr::Currency.parse!(params[:amount]), txid: params[:txid]
    )
    render json: { payload: code.to_s }
  rescue RailsBr::InvalidValueError => e
    render json: { error: e.message }, status: 422
  end
end
