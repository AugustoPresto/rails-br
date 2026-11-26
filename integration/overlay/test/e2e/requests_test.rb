require_relative "support"

class RequestsTest < ActionDispatch::IntegrationTest
  test "formulário HTTP com dados brasileiros cria e devolve o registro formatado" do
    post "/customers", params: { customer: {
      name: "Maria", cpf: FakeDocuments.cpf, birth_on: "05/01/1985", credit_limit: "R$ 1.500,00"
    } }

    assert_response 201
    body = JSON.parse(response.body)
    assert_equal "05/01/1985", body["birth_on"]
    assert_equal "R$ 1.500,00", body["credit_limit"]

    get "/customers/#{body['id']}"
    assert_response 200
  end

  test "formulário HTTP inválido devolve 422 com as mensagens" do
    post "/customers", params: { customer: { name: "x", cpf: "123", birth_on: "2026-01-01" } }

    assert_response 422
    assert_equal 2, JSON.parse(response.body)["errors"].length
  end

  test "parâmetros de tipos inesperados não derrubam a aplicação" do
    [{ cpf: ["1"] }, { birth_on: { a: "b" } }, { credit_limit: "\u0000" }, { cpf: "x" * 100_000 }].each do |extra|
      post "/customers", params: { customer: { name: "x" }.merge(extra) }

      assert_includes [201, 400, 422], response.status, extra.keys.inspect
    end
  end

  test "JSON com números em ponto flutuante é recusado, não convertido" do
    post "/customers", params: { customer: { name: "x", credit_limit: 10.5 } }, as: :json

    assert_response 422
  end

  test "gera um BR Code que a própria gem valida" do
    get "/pix", params: { key: "pix@example.com", name: "Loja São João", city: "Goiânia", amount: "R$ 99,90" }

    assert_response 200
    code = RailsBr::Pix::BRCode.new(JSON.parse(response.body)["payload"])
    assert code.valid?, code.error
    assert_equal BigDecimal("99.90"), code.amount
    assert_equal "Goiania", code.city
  end

  test "dados inválidos do Pix devolvem 422" do
    get "/pix", params: { key: "lixo", name: "x", city: "y" }

    assert_response 422
  end
end
