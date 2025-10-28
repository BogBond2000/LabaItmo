# Лабораторная работа №1

## Бондарь Богдан P3216

### Problem 6 (Sum Square Difference)
Суть задачи очень проста,приходит массив чисел,мне необходимо просуммировать все элемеенты массива и возвести их в квадрат,
затем от полученной суммы нуобходимо отнять число,равное сумме квадратов элемента массивов
## Обычная рекурсия
```elxir
  def problem6_monolithic_recursion(n) do
  square_sum_rec(n, 0) - sum_squares_rec(n, 0)

end

defp sum_squares_rec(0, acc), do: acc
defp sum_squares_rec(n, acc), do: sum_squares_rec(n - 1, acc + n * n)

defp square_sum_rec(0, acc), do: acc * acc
defp square_sum_rec(n, acc), do: square_sum_rec(n - 1, acc + n)
```
### Особенности данной реализации:
  -В елексире необходимо всегда подтягивать аккумулятор
  

## 2. Модульный подход
```elixir
def problem6_modular(n) do
  square_sum_modular(n) - sum_squares_modular(n)
end

def sum_squares_modular(n) do
  1..n
  |> Enum.map(&(&1 * &1))
  |> Enum.reduce(0, &+/2)
end

def square_sum_modular(n) do
  1..n
  |> Enum.reduce(0, &+/2)
  |> then(&(&1 * &1))
end
```
- В данно реализации я продемонсрировал работу с lamda функциями и операторами захвата 
- Плюс данного решения - читаемость и простота тестирования
- Пример: `fibonachi_recursion/1`

## 3. Побаловался с генераторами списков и Enum.
```elxir
def problem6_comprehension(n) do
  square_sum = for(x <- 1..n, do: x) |> Enum.sum() |> then(&(&1 * &1))
  sum_squares = for(x <- 1..n, do: x * x) |> Enum.sum()
  square_sum - sum_squares
end
```
- Декларативный стиль
- Потоковая обработка 

### Problem 25 (-digit Fibonacci Number)
Суть задачи посчитать n-ое число Фибоначчи

## Хвостовая рекурсия
```elixir
def problem2_tail_recursion(limit) do
  fib_even_sum_tail(limit, 1, 0, 0)
end

defp fib_even_sum_tail(limit, a, _b, sum) when a > limit, do: sum

defp fib_even_sum_tail(limit, a, b, sum) when rem(a, 2) == 0 do
  fib_even_sum_tail(limit, a + b, a, sum + a)
end

defp fib_even_sum_tail(limit, a, b, sum) do
  fib_even_sum_tail(limit, a + b, a, sum)
end
```
-оптимизация компилятором
