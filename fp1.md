# Лабораторная работа №1

## Бондарь Богдан P3216

### Problem 6 (Sum Square Difference)
Суть задачи: для чисел от 1 до n необходимо вычислить разность между квадратом суммы и суммой квадратов этих чисел.

## 1. Хвостовая рекурсия
```elixir
def problem6_tail(n) do
  square_sum(n, 0) - sum_squares(n, 0)
end

defp sum_squares(0, acc), do: acc
defp sum_squares(n, acc), do: sum_squares(n - 1, acc + n * n)

defp square_sum(0, acc), do: acc * acc
defp square_sum(n, acc), do: square_sum(n - 1, acc + n)
```

### Особенности реализации:
- Используется хвостовая рекурсия для оптимизации
- Аккумуляторы накапливают промежуточные результаты
- Компилятор Elixir оптимизирует хвостовую рекурсию

## 2. Модульный подход
```elixir
def problem6_modular(n) do
  square_sum_modular(n) - sum_squares_modular(n)
end

defp sum_squares_modular(n) do
  1..n
  |> Enum.map(&(&1 * &1))
  |> Enum.sum()
end

defp square_sum_modular(n) do
  1..n
  |> Enum.sum()
  |> then(&(&1 * &1))
end
```

### Особенности реализации:
- Применяются lambda-функции и операторы захвата
- Используются операторы захвата аргументов

## 3. Генераторы списков
```elixir
def problem6_for(n) do
  square_sum = for(x <- 1..n, do: x) |> Enum.sum() |> then(&(&1 * &1))
  sum_squares = for(x <- 1..n, do: x * x) |> Enum.sum()
  square_sum - sum_squares
end
```

### Особенности реализации:
- Декларативный стиль программирования
- Использование генераторов списков

---

### Problem 25 (1000-digit Fibonacci Number)
Суть задачи: найти индекс первого числа Фибоначчи, содержащего заданное количество цифр.

## 1. Хвостовая рекурсия
```elixir
def problem25_tail(digits) do
  find_fib_index(digits, 2, 1, 1)
end

defp find_fib_index(digits, index, a, b) do
  if digit_count(a) >= digits do
    index
  else
    find_fib_index(digits, index + 1, b, a + b)
  end
end
```

### Особенности реализации:
- Хвостовая рекурсия для эффективного вычисления
- Начинаем с F(1)=1, F(2)=1 (индекс 2)
- Проверяем количество цифр на каждом шаге

## 2. Stream-реализация
```elixir
def problem25_stream(digits) do
  fib_stream()
  |> Stream.with_index(1)
  |> Stream.filter(fn {num, _} -> digit_count(num) >= digits end)
  |> Enum.take(1)
  |> hd()
  |> elem(1)
end
```

### Особенности реализации:
- Ленивые вычисления с помощью Stream
- Фильтрация по количеству цифр
- Эффективная работа с большими последовательностями

## 3. Модульный подход
```elixir
def problem25_modular(digits) do
  fib_stream()
  |> Stream.with_index(1)
  |> filter_by_digits(digits)
  |> get_first_index()
end

defp filter_by_digits(stream, digits) do
  Stream.filter(stream, fn {num, _} -> digit_count(num) >= digits end)
end

defp get_first_index(stream) do
  stream
  |> Enum.take(1)
  |> hd()
  |> elem(1)
end
```

### Особенности реализации:
- Разделение ответственности между функциями
- Повышенная читаемость кода
- Легкость тестирования отдельных компонентов

## Вспомогательные функции

```elixir
defp digit_count(n) do
  n
  |> Integer.digits()
  |> length()
end

defp fib_stream do
  Stream.unfold({1, 1}, fn {a, b} -> {a, {b, a + b}} end)
end
```

### Особенности:
- `digit_count/1` - подсчет цифр через преобразование в список
- `fib_stream/0` - генератор бесконечной последовательности Фибоначчи
- Ленивые вычисления для работы с большими числами

