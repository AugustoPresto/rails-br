# Dispara requisições simultâneas contra o Puma em produção e confere cada
# resposta. Roda fora do Rails (só biblioteca padrão).
require "json"
require "net/http"

BASE = URI("http://127.0.0.1:3000")
THREADS = 32
PER_THREAD = 100
VALID_CPF = "11144477735".freeze

def request(klass, path, form = nil)
  Net::HTTP.start(BASE.host, BASE.port, read_timeout: 60) do |http|
    req = klass.new(path)
    req.set_form_data(form) if form
    http.request(req)
  end
end

60.times do
  break if begin
    request(Net::HTTP::Get, "/pix?key=a@b&name=x&city=y")
  rescue Errno::ECONNREFUSED
    false
  end

  sleep 1
end

failures = Queue.new
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

THREADS.times.map do |t|
  Thread.new do
    PER_THREAD.times do |i|
      kind = (t + i) % 4
      response, expected =
        case kind
        when 0
          [request(Net::HTTP::Post, "/customers", "customer[name]" => "t#{t}", "customer[cpf]" => VALID_CPF,
                                                  "customer[birth_on]" => "01/02/1990",
                                                  "customer[credit_limit]" => "#{i},50"), "201"]
        when 1
          [request(Net::HTTP::Post, "/customers", "customer[name]" => "x", "customer[cpf]" => "123"), "422"]
        when 2
          [request(Net::HTTP::Get, "/pix?key=a@b&name=Loja&city=Goiania&amount=#{i + 1},00&txid=T#{t}N#{i}"), "200"]
        else
          [request(Net::HTTP::Get, "/pix?key=invalida&name=x&city=y"), "422"]
        end
      ok = response.code == expected
      ok &&= JSON.parse(response.body)["credit_limit"].end_with?(",50") if kind.zero?
      ok &&= JSON.parse(response.body)["payload"].include?("T#{t}N#{i}") if kind == 2
      failures << "#{response.code} (esperado #{expected}) #{response.body[0, 200]}" unless ok
    rescue StandardError => e
      failures << "#{e.class}: #{e.message}"
    end
  end
end.each(&:join)

total = THREADS * PER_THREAD
elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
puts "requisições: #{total}, falhas: #{failures.size}, #{(total / elapsed).round} req/s (#{THREADS} threads)"
10.times { puts failures.pop unless failures.empty? }
exit(failures.empty? ? 0 : 1)
