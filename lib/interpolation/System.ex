# system.ex
defmodule Interpolation.System do
  def main(args) do
    # Парсим аргументы
    {opts, _, _} = OptionParser.parse(args,
      switches: [linear: :boolean, newton: :boolean, lagrange: :boolean,
        gauss: :boolean, step: :float, window: :integer, help: :boolean],
      aliases: [l: :linear, n: :newton, s: :step, w: :window, h: :help])

    if opts[:help] do
      IO.puts("mix run -- --linear --step 0.5")
      System.halt(0)
    end

    # Выбираем алгоритмы
    algs = []
    algs = if opts[:linear], do: [:linear | algs], else: algs
    algs = if opts[:newton], do: [:newton | algs], else: algs
    algs = if opts[:lagrange], do: [:lagrange | algs], else: algs
    algs = if opts[:gauss], do: [:gauss | algs], else: algs

    if algs == [] do
      IO.puts("Выбери алгоритм! --linear, --newton и т.д.")
      System.halt(1)
    end

    step = opts[:step] || 0.5
    window = opts[:window] || 4

    # Запускаем все
    printer = spawn(Interpolation.Printer, :start, [])
    calc = spawn(Interpolation.Calculate, :start, [algs, step, window, printer])
    reader = spawn(Interpolation.Reader, :start_reader, [calc])

    # Ждем
    Process.monitor(reader)
    receive do
      {:DOWN, _, _, _, _} -> :ok
    end
  end
end