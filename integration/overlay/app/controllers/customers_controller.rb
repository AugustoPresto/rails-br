class CustomersController < ApplicationController
  skip_forgery_protection

  def create
    customer = Customer.new(customer_params)
    if customer.save
      render json: present(customer), status: 201
    else
      render json: { errors: customer.errors.full_messages }, status: 422
    end
  end

  def show
    render json: present(Customer.find(params[:id]))
  end

  private

  def customer_params
    params.require(:customer).permit(:name, :cpf, :cnpj, :pix_key, :birth_on, :credit_limit)
  end

  def present(customer)
    {
      id: customer.id,
      cpf: customer.cpf,
      birth_on: customer.birth_on && RailsBr::DateFormat.format(customer.birth_on),
      credit_limit: customer.credit_limit && RailsBr::Currency.format(customer.credit_limit)
    }
  end
end
