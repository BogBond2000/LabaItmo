# test_integration.exs
IO.puts("=== ИНТЕГРАЦИОННЫЙ ТЕСТ ===")

# Тестируем парсер Reader
IO.puts("\n1. 📖 Тест парсера Reader:")

test_cases = [
  "1.0 2.0",
  "3\t4",
  "5;6",
  "7 8.5",
  "abc def",
  "",
  "10",
  "1 2 3"
]

Enum.each(test_cases, fn test_input ->
  result = Interpolation.Reader.parse_line(test_input)

  case result do
    {:ok, {x, y}} ->
      IO.puts("  ✅ '#{test_input}' → x=#{x}, y=#{y}")

    {:error, reason} ->
      IO.puts("  ❌ '#{test_input}' → ошибка: #{inspect(reason)}")
  end
end)

# Тестируем System
IO.puts("\n2. ⚙️  Тест System (определение алгоритмов):")

options1 = [linear: true, newton: true]
options2 = [gauss: false, lagrange: false]
options3 = [linear: true, newton: true, lagrange: true, gauss: true]

IO.puts("  Тест 1: #{inspect(Interpolation.System.determine_algorithms(options1))}")
IO.puts("  Тест 2: #{inspect(Interpolation.System.determine_algorithms(options2))}")
IO.puts("  Тест 3: #{inspect(Interpolation.System.determine_algorithms(options3))}")

# Тест отправки сообщений
IO.puts("\n3. 📨 Тест отправки сообщений Reader → Calculator:")

calculator_pid = spawn(fn ->
  IO.puts("  🧮 Calculator запущен")

  receive do
    {:data_point, {x, y}} ->
      IO.puts("  ✅ Получил точку: (#{x}, #{y})")

    :eof ->
      IO.puts("  ✅ Получил EOF")

    other ->
      IO.puts("  ❌ Неизвестное сообщение: #{inspect(other)}")
  end
end)

# Имитируем работу Reader
IO.puts("  📖 Reader отправляет тестовые данные...")
send(calculator_pid, {:data_point, {1.5, 3.0}})
send(calculator_pid, {:data_point, {2.0, 4.0}})
send(calculator_pid, :eof)

# Ждем обработки
:timer.sleep(500)

IO.puts("\n🎯 Все тесты завершены!")