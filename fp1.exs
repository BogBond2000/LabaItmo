defmodule MyProject do
  def sum_square() do
    Enum.reduce(1..100,0,&+/2) ** 2
  end
  def square_sum() do
    1..100 |> Enum.map(&(&1*&1)) |> Enum.reduce(0,&+/2)
  end

  def fibonachi(n) when n > 0 do
      fib_help(n,1,0)
  end
  defp fib_help(n,a,b) when n==1 do
    a
  end
  defp fib_help(n,a,b) do
    fib_help(n-1,a+b,a)
  end
end

b = MyProject.fibonachi(100)
IO.puts(b)
