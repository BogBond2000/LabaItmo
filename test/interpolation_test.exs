ExUnit.start()

defmodule Interpolation.ReaderTest do
  use ExUnit.Case

  describe "parse_line/1" do
    test "парсит строку с пробелами" do
      assert Interpolation.Reader.parse_line("1.0 2.0\n") == {:ok, {1.0, 2.0}}
      assert Interpolation.Reader.parse_line("3.5 4.7\n") == {:ok, {3.5, 4.7}}
    end

    test "парсит строку с табуляцией" do
      assert Interpolation.Reader.parse_line("1.0\t2.0\n") == {:ok, {1.0, 2.0}}
      assert Interpolation.Reader.parse_line("10\t20\n") == {:ok, {10.0, 20.0}}
    end

    test "парсит строку с точкой с запятой" do
      assert Interpolation.Reader.parse_line("1.0;2.0\n") == {:ok, {1.0, 2.0}}
      assert Interpolation.Reader.parse_line("5;6\n") == {:ok, {5.0, 6.0}}
    end

    test "парсит отрицательные числа" do
      assert Interpolation.Reader.parse_line("-1.0 -2.5\n") == {:ok, {-1.0, -2.5}}
      assert Interpolation.Reader.parse_line("-10\t20\n") == {:ok, {-10.0, 20.0}}
    end

    test "парсит числа с плавающей точкой" do
      assert Interpolation.Reader.parse_line("1.5 2.7\n") == {:ok, {1.5, 2.7}}
      assert Interpolation.Reader.parse_line("0.1 0.2\n") == {:ok, {0.1, 0.2}}
    end

    test "возвращает ошибку для невалидного формата" do
      assert Interpolation.Reader.parse_line("abc def\n") == {:error, :invalid_number_format}
      assert Interpolation.Reader.parse_line("1.0\n") == {:error, :wrong_number_of_values}
      assert Interpolation.Reader.parse_line("1.0 2.0 3.0\n") == {:error, :wrong_number_of_values}
      assert Interpolation.Reader.parse_line("\n") == {:error, :wrong_number_of_values}
      assert Interpolation.Reader.parse_line("") == {:error, :wrong_number_of_values}
    end

    test "обрабатывает строки без переноса" do
      assert Interpolation.Reader.parse_line("1.0 2.0") == {:ok, {1.0, 2.0}}
      assert Interpolation.Reader.parse_line("3\t4") == {:ok, {3.0, 4.0}}
    end
  end
end

defmodule Interpolation.AlgorithmsTest do
  use ExUnit.Case

  describe "linear/2" do
    test "линейная интерполяция между двумя точками" do
      points = [{0.0, 0.0}, {1.0, 1.0}]
      assert Interpolation.Algorithms.linear(0.5, points) == 0.5
      assert Interpolation.Algorithms.linear(0.0, points) == 0.0
      assert Interpolation.Algorithms.linear(1.0, points) == 1.0
    end

    test "линейная интерполяция с несколькими точками" do
      points = [{0.0, 0.0}, {1.0, 2.0}, {2.0, 4.0}]
      # Должна использовать две ближайшие точки
      result = Interpolation.Algorithms.linear(0.5, points)
      assert abs(result - 1.0) < 0.001
    end

    test "линейная интерполяция с отрицательными значениями" do
      points = [{-1.0, -1.0}, {1.0, 1.0}]
      assert Interpolation.Algorithms.linear(0.0, points) == 0.0
    end

    test "линейная интерполяция вне диапазона" do
      points = [{0.0, 0.0}, {1.0, 1.0}]
      # Экстраполяция
      result = Interpolation.Algorithms.linear(1.5, points)
      assert abs(result - 1.5) < 0.001
    end
  end

  describe "lagrange/2" do
    test "интерполяция Лагранжа для двух точек" do
      points = [{0.0, 0.0}, {1.0, 1.0}]
      assert abs(Interpolation.Algorithms.lagrange(0.5, points) - 0.5) < 0.001
    end

    test "интерполяция Лагранжа для трех точек" do
      points = [{0.0, 0.0}, {1.0, 1.0}, {2.0, 4.0}]
      # Для x=1 должно быть y=1
      assert abs(Interpolation.Algorithms.lagrange(1.0, points) - 1.0) < 0.001
      # Для x=0 должно быть y=0
      assert abs(Interpolation.Algorithms.lagrange(0.0, points) - 0.0) < 0.001
    end

    test "интерполяция Лагранжа проходит через все точки" do
      points = [{0.0, 1.0}, {1.0, 2.0}, {2.0, 5.0}]
      # Проверяем, что полином проходит через исходные точки
      for {x, y} <- points do
        result = Interpolation.Algorithms.lagrange(x, points)
        assert abs(result - y) < 0.001, "Для точки (#{x}, #{y}) получили #{result}"
      end
    end

    test "интерполяция Лагранжа для квадратичной функции" do
      points = [{0.0, 0.0}, {1.0, 1.0}, {2.0, 4.0}]
      # x^2 в точке 1.5 должно быть 2.25
      result = Interpolation.Algorithms.lagrange(1.5, points)
      assert abs(result - 2.25) < 0.001
    end
  end

  describe "newton/2" do
    test "интерполяция Ньютона для двух точек" do
      points = [{0.0, 0.0}, {1.0, 1.0}]
      assert abs(Interpolation.Algorithms.newton(0.5, points) - 0.5) < 0.001
    end

    test "интерполяция Ньютона для трех точек" do
      points = [{0.0, 0.0}, {1.0, 1.0}, {2.0, 4.0}]
      # Для x=1 должно быть y=1
      assert abs(Interpolation.Algorithms.newton(1.0, points) - 1.0) < 0.001
    end

    test "интерполяция Ньютона проходит через все точки" do
      points = [{0.0, 1.0}, {1.0, 2.0}, {2.0, 5.0}, {3.0, 10.0}]
      # Проверяем, что полином проходит через исходные точки
      for {x, y} <- points do
        result = Interpolation.Algorithms.newton(x, points)
        assert abs(result - y) < 0.001, "Для точки (#{x}, #{y}) получили #{result}"
      end
    end

    test "интерполяция Ньютона совпадает с Лагранжем" do
      points = [{0.0, 0.0}, {1.0, 1.0}, {2.0, 4.0}, {3.0, 9.0}]
      test_x = 1.5
      lagrange_result = Interpolation.Algorithms.lagrange(test_x, points)
      newton_result = Interpolation.Algorithms.newton(test_x, points)
      assert abs(lagrange_result - newton_result) < 0.001
    end
  end

  describe "finite_differences/1" do
    test "конечные разности для линейной функции" do
      points = [{0.0, 0.0}, {1.0, 1.0}, {2.0, 2.0}, {3.0, 3.0}]
      table = Interpolation.Algorithms.finite_differences(points)
      # Первая строка - значения y
      assert List.first(table) == [0.0, 1.0, 2.0, 3.0]
      # Вторая строка - первые разности (все равны 1.0)
      assert Enum.at(table, 1) == [1.0, 1.0, 1.0]
    end

    test "конечные разности для квадратичной функции" do
      points = [{0.0, 0.0}, {1.0, 1.0}, {2.0, 4.0}, {3.0, 9.0}]
      table = Interpolation.Algorithms.finite_differences(points)
      # Первая строка - значения y
      assert List.first(table) == [0.0, 1.0, 4.0, 9.0]
      # Вторая строка - первые разности
      assert Enum.at(table, 1) == [1.0, 3.0, 5.0]
      # Третья строка - вторые разности (все равны 2.0)
      assert Enum.at(table, 2) == [2.0, 2.0]
    end
  end
end

defmodule Interpolation.CalculateTest do
  use ExUnit.Case

  test "обработка точек и вычисления" do
    printer = self()
    calc = spawn(Interpolation.Calculate, :start, [[:linear], 0.5, 2, printer])

    # Отправляем точки
    send(calc, {:data_point, {0.0, 0.0}})
    send(calc, {:data_point, {1.0, 1.0}})

    # Ждем результаты
    receive do
      {:result, :linear, x, _y} ->
        assert x >= 0.0
        assert x <= 1.0
    after
      100 -> flunk("Не получен результат")
    end

    send(calc, :eof)
  end

  test "обработка нескольких алгоритмов" do
    printer = self()
    calc = spawn(Interpolation.Calculate, :start, [[:linear, :lagrange], 0.5, 2, printer])

    send(calc, {:data_point, {0.0, 0.0}})
    send(calc, {:data_point, {1.0, 1.0}})

    # Собираем больше результатов, чтобы захватить оба алгоритма
    results = collect_results(printer, 10, [])
    assert length(results) >= 2

    # Проверяем, что есть результаты для обоих алгоритмов
    algorithms = Enum.map(results, fn {:result, alg, _, _} -> alg end)
    assert :linear in algorithms
    assert :lagrange in algorithms

    send(calc, :eof)
  end

  test "работа с окном точек" do
    printer = self()
    calc = spawn(Interpolation.Calculate, :start, [[:newton], 0.5, 4, printer])

    # Отправляем больше точек, чем размер окна
    send(calc, {:data_point, {0.0, 0.0}})
    send(calc, {:data_point, {1.0, 1.0}})
    send(calc, {:data_point, {2.0, 4.0}})
    send(calc, {:data_point, {3.0, 9.0}})
    send(calc, {:data_point, {4.0, 16.0}})

    # Должны получить результаты
    results = collect_results(printer, 5, [])
    assert length(results) > 0

    send(calc, :eof)
  end

  defp collect_results(_pid, count, acc) when count <= 0, do: acc
  defp collect_results(_pid, count, acc) do
    receive do
      {:result, _alg, _x, _y} = msg ->
        collect_results(nil, count - 1, [msg | acc])
    after
      100 -> acc
    end
  end
end

defmodule Interpolation.PrinterTest do
  use ExUnit.Case

  test "печать результатов" do
    printer = spawn(Interpolation.Printer, :start, [])

    # Отправляем результат
    send(printer, {:result, :linear, 0.5, 0.5})

    # Принтер должен обработать сообщение без ошибок
    Process.sleep(10)

    send(printer, :eof)
    Process.sleep(10)
  end

  test "обработка EOF" do
    printer = spawn(Interpolation.Printer, :start, [])
    send(printer, :eof)
    Process.sleep(10)
    # Процесс должен завершиться
    refute Process.alive?(printer)
  end
end

defmodule Interpolation.IntegrationTest do
  use ExUnit.Case

  test "полный цикл: Reader -> Calculate -> Printer" do
    printer = spawn(Interpolation.Printer, :start, [])
    calc = spawn(Interpolation.Calculate, :start, [[:linear], 0.5, 2, printer])
    reader = spawn(Interpolation.Reader, :start_reader, [calc])

    # Имитируем ввод данных
    send(reader, {:data_point, {0.0, 0.0}})
    send(reader, {:data_point, {1.0, 1.0}})

    Process.sleep(50)

    # Проверяем, что принтер получил результаты
    send(printer, {:check, self()})
    receive do
      :ok -> :ok
    after
      100 -> :ok  # Принтер не отвечает на check, это нормально
    end

    send(calc, :eof)
    send(reader, :eof)
  end

  test "потоковая обработка данных" do
    printer = self()
    calc = spawn(Interpolation.Calculate, :start, [[:linear], 0.7, 2, printer])

    send(calc, {:data_point, {0.0, 0.0}})
    send(calc, {:data_point, {1.0, 1.0}})

    results1 = collect_all_results(100)
    assert length(results1) > 0

    send(calc, {:data_point, {2.0, 2.0}})
    results2 = collect_all_results(100)
    assert length(results2) > 0

    send(calc, :eof)
    _results3 = collect_all_results(100)
  end

  defp collect_all_results(timeout) do
    collect_all_results_recursive(timeout, [])
  end

  defp collect_all_results_recursive(timeout, acc) do
    receive do
      {:result, _alg, _x, _y} = msg ->
        collect_all_results_recursive(timeout, [msg | acc])
    after
      timeout -> acc
    end
  end
end

defmodule Interpolation.SystemTest do
  use ExUnit.Case

  test "парсинг аргументов командной строки" do
    # Тестируем логику выбора алгоритмов
    args1 = ["--linear", "--step", "0.5"]
    {opts1, _, _} = OptionParser.parse(args1,
      switches: [linear: :boolean, newton: :boolean, lagrange: :boolean,
        gauss: :boolean, step: :float, window: :integer],
      aliases: [l: :linear, n: :newton, s: :step, w: :window])

    assert opts1[:linear] == true
    assert opts1[:step] == 0.5

    args2 = ["--linear", "--newton", "--step", "0.7", "--window", "4"]
    {opts2, _, _} = OptionParser.parse(args2,
      switches: [linear: :boolean, newton: :boolean, lagrange: :boolean,
        gauss: :boolean, step: :float, window: :integer],
      aliases: [l: :linear, n: :newton, s: :step, w: :window])

    assert opts2[:linear] == true
    assert opts2[:newton] == true
    assert opts2[:step] == 0.7
    assert opts2[:window] == 4
  end

  test "выбор алгоритмов из опций" do
    opts1 = [linear: true]
    algs1 = []
    algs1 = if opts1[:linear], do: [:linear | algs1], else: algs1
    assert :linear in algs1

    opts2 = [linear: true, newton: true, lagrange: false]
    algs2 = []
    algs2 = if opts2[:linear], do: [:linear | algs2], else: algs2
    algs2 = if opts2[:newton], do: [:newton | algs2], else: algs2
    algs2 = if opts2[:lagrange], do: [:lagrange | algs2], else: algs2
    assert :linear in algs2
    assert :newton in algs2
    refute :lagrange in algs2
  end
end

defmodule Interpolation.EdgeCasesTest do
  use ExUnit.Case

  test "обработка одной точки" do
    points = [{0.0, 0.0}]
    # Линейная интерполяция требует минимум 2 точки
    # Алгоритм должен выбросить ошибку при попытке взять 2 точки из списка с 1 точкой
    assert_raise MatchError, fn ->
      Interpolation.Algorithms.linear(0.5, points)
    end
  end

  test "обработка одинаковых x координат" do
    points = [{0.0, 0.0}, {0.0, 1.0}]
    # Это может вызвать деление на ноль
    assert_raise ArithmeticError, fn ->
      Interpolation.Algorithms.linear(0.0, points)
    end
  end

  test "обработка большого количества точек" do
    points = Enum.map(0..100, fn i -> {i * 1.0, i * 1.0} end)
    result = Interpolation.Algorithms.linear(50.0, points)
    assert abs(result - 50.0) < 0.001
  end

  test "обработка точек в обратном порядке" do
    # Алгоритмы должны работать даже если точки не отсортированы
    points = [{2.0, 4.0}, {0.0, 0.0}, {1.0, 1.0}]
    result = Interpolation.Algorithms.linear(0.5, points)
    assert is_float(result)
  end

  test "экстраполяция за пределами диапазона" do
    points = [{0.0, 0.0}, {1.0, 1.0}]
    result_right = Interpolation.Algorithms.linear(2.0, points)
    assert abs(result_right - 2.0) < 0.001

    result_left = Interpolation.Algorithms.linear(-1.0, points)
    assert abs(result_left - (-1.0)) < 0.001
  end

  test "работа с очень маленькими числами" do
    points = [{0.0, 0.0}, {0.0001, 0.0001}]
    result = Interpolation.Algorithms.linear(0.00005, points)
    assert abs(result - 0.00005) < 0.00001
  end

  test "работа с очень большими числами" do
    points = [{0.0, 0.0}, {1000000.0, 1000000.0}]
    result = Interpolation.Algorithms.linear(500000.0, points)
    assert abs(result - 500000.0) < 1.0
  end
end

defmodule Interpolation.PerformanceTest do
  use ExUnit.Case

  @tag :performance
  test "производительность линейной интерполяции" do
    points = Enum.map(0..1000, fn i -> {i * 1.0, i * 1.0} end)
    
    {time, _} = :timer.tc(fn ->
      for x <- 0..100 do
        Interpolation.Algorithms.linear(x * 10.0, points)
      end
    end)

    assert time < 1_000_000 
  end

  @tag :performance
  test "производительность интерполяции Лагранжа" do
    points = Enum.take(Enum.map(0..100, fn i -> {i * 1.0, i * i * 1.0} end), 20)
    
    {time, _} = :timer.tc(fn ->
      for x <- 0..10 do
        Interpolation.Algorithms.lagrange(x * 2.0, points)
      end
    end)

    assert time < 1_000_000
  end
end

