defmodule MyProject do
  def problem6_monolithic_recursion(n) do
    square_sum_rec(n, 0) - sum_squares_rec(n, 0)
  end

  defp sum_squares_rec(0, acc), do: acc
  defp sum_squares_rec(n, acc), do: sum_squares_rec(n - 1, acc + n * n)

  defp square_sum_rec(0, acc), do: acc * acc
  defp square_sum_rec(n, acc), do: square_sum_rec(n - 1, acc + n)

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

  def problem6_comprehension(n) do
    square_sum = for(x <- 1..n, do: x) |> Enum.sum() |> then(&(&1 * &1))
    sum_squares = for(x <- 1..n, do: x * x) |> Enum.sum()
    square_sum - sum_squares
  end

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

  def problem2_naive_recursion(limit) do
    fib_even_sum_naive(limit, 1, 0)
  end

  defp fib_even_sum_naive(limit, a, b) when a > limit, do: 0

  defp fib_even_sum_naive(limit, a, b) when rem(a, 2) == 0 do
    a + fib_even_sum_naive(limit, a + b, a)
  end

  defp fib_even_sum_naive(limit, a, b) do
    fib_even_sum_naive(limit, a + b, a)
  end

  def problem2_stream(limit) do
    fibonacci_stream()
    |> Stream.take_while(&(&1 <= limit))
    |> Stream.filter(&(rem(&1, 2) == 0))
    |> Enum.sum()
  end

  def fibonacci_stream do
    Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
    # Пропускаем 0
    |> Stream.drop(1)
  end

  def problem2_modular(limit) do
    generate_fibonacci_up_to(limit)
    |> filter_even_numbers()
    |> reduce_sum()
  end

  defp generate_fibonacci_up_to(limit) do
    Stream.unfold({0, 1}, fn {a, b} ->
      if a <= limit, do: {a, {b, a + b}}, else: nil
    end)
    |> Enum.to_list()
    # Убираем 0
    |> tl()
  end

  defp filter_even_numbers(numbers) do
    Enum.filter(numbers, &(rem(&1, 2) == 0))
  end

  defp reduce_sum(numbers) do
    Enum.reduce(numbers, 0, &+/2)
  end

  def fibonachi(n) when n > 0 do
    fib_help(n, 1, 0)
  end

  defp fib_help(1, a, _b), do: a

  defp fib_help(n, a, b) do
    fib_help(n - 1, a + b, a)
  end

  def fibonachi_recursion(n) when n <= 2 do
    1
  end

  def fibonachi_recursion(n) when n > 2 do
    fibonachi_recursion(n - 1) + fibonachi_recursion(n - 2)
  end
end
