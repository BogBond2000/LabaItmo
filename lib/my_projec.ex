defmodule MyProject do
  def problem6_tail(n) do
    square_sum(n, 0) - sum_squares(n, 0)
  end

  defp sum_squares(0, acc), do: acc
  defp sum_squares(n, acc), do: sum_squares(n - 1, acc + n * n)

  defp square_sum(0, acc), do: acc * acc
  defp square_sum(n, acc), do: square_sum(n - 1, acc + n)

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

  def problem6_for(n) do
    square_sum = for(x <- 1..n, do: x) |> Enum.sum() |> then(&(&1 * &1))
    sum_squares = for(x <- 1..n, do: x * x) |> Enum.sum()
    square_sum - sum_squares
  end

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

  def problem25_stream(digits) do
    fib_stream()
    |> Stream.with_index(1)
    |> Stream.filter(fn {num, _} -> digit_count(num) >= digits end)
    |> Enum.take(1)
    |> hd()
    |> elem(1)
  end

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

  defp digit_count(n) do
    n
    |> Integer.digits()
    |> length()
  end

  defp fib_stream do
    Stream.unfold({1, 1}, fn {a, b} -> {a, {b, a + b}} end)
  end
end
