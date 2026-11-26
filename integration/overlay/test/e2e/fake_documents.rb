# Geradores independentes da gem, para ela não validar o próprio cálculo.
module FakeDocuments
  module_function

  def cpf(random = Random.new)
    base = Array.new(9) { random.rand(10) }
    return cpf(random) if base.uniq.length == 1

    2.times do
      weight = base.length + 1
      rest = base.each_with_index.sum { |digit, i| digit * (weight - i) } % 11
      base << (rest < 2 ? 0 : 11 - rest)
    end
    base.join
  end

  def cnpj(random = Random.new, alphanumeric: false)
    alphabet = ("0".."9").to_a
    alphabet += ("A".."Z").to_a if alphanumeric
    chars = Array.new(12) { alphabet[random.rand(alphabet.length)] }
    return cnpj(random, alphanumeric: alphanumeric) if chars.uniq.length == 1

    [[5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2], [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]].each do |weights|
      rest = chars.zip(weights).sum { |char, weight| (char.ord - 48) * weight } % 11
      chars << (rest < 2 ? 0 : 11 - rest).to_s
    end
    chars.join
  end
end
