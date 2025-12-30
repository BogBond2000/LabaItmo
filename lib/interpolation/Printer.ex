defmodule Interpolation.Printer do
  def start do
    loop()
  end

  defp loop do
    receive do
      {:result, algorithm, x, y} ->
        IO.puts("#{algorithm}: #{x} #{y}")
        loop()

      :eof ->
        :ok
    end
  end
end