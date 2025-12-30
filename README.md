# ОТЧЕТ ПО ЛАБОРАТОРНОЙ РАБОТЕ

## ТИТУЛЬНЫЙ ЛИСТ

**Лабораторная работа №3 по предмету "Функциональное программирование"**

**Тема:** Потоковая интерполяция данных


**Язык программирования:** Elixir


---


## 1. ОПИСАНИЕ АЛГОРИТМОВ ИНТЕРПОЛЯЦИИ

### 1.1. Линейная интерполяция

**Алгоритм:** Интерполяция отрезками

**Формула:**
```
y = y1 + (y2 - y1) * (x - x1) / (x2 - x1)
```

**Описание:**
- Для заданной точки x находятся две ближайшие точки из входных данных
- Значение y вычисляется по формуле линейной интерполяции между этими точками
- Требуется минимум 2 точки для работы

### 1.2. Интерполяция Лагранжа

**Алгоритм:** Полиномиальная интерполяция через базисные полиномы

**Формула:**
```
P(x) = Σ(i=0 to n) yi * Li(x)

где Li(x) = Π(j=0 to n, j≠i) (x - xj) / (xi - xj)
```

**Описание:**
- Строится полином n-й степени, проходящий через все n+1 точку
- Используются базисные полиномы Лагранжа
- Требуется минимум window точек (по умолчанию 4)

### 1.3. Интерполяция Ньютона

**Алгоритм:** Полиномиальная интерполяция через разделенные разности

**Формула:**
```
P(x) = f[x0] + f[x0,x1](x-x0) + f[x0,x1,x2](x-x0)(x-x1) + ...
```

**Описание:**
- Строится таблица разделенных разностей
- Полином вычисляется по формуле Ньютона
- Требуется минимум window точек (по умолчанию 4)

---

## 2. КЛЮЧЕВЫЕ ЭЛЕМЕНТЫ РЕАЛИЗАЦИИ


### 2.1. Модуль System.ex

**Назначение:** Инициализация системы, парсинг аргументов командной строки

```elixir
defmodule Interpolation.System do
  def main(args) do
    {opts, _, _} = OptionParser.parse(args,
      switches: [linear: :boolean, newton: :boolean, lagrange: :boolean,
        gauss: :boolean, step: :float, window: :integer, help: :boolean],
      aliases: [l: :linear, n: :newton, s: :step, w: :window, h: :help])
    
    algs = []
    algs = if opts[:linear], do: [:linear | algs], else: algs
    algs = if opts[:newton], do: [:newton | algs], else: algs
    
    printer = spawn(Interpolation.Printer, :start, [])
    calc = spawn(Interpolation.Calculate, :start, [algs, step, window, printer])
    reader = spawn(Interpolation.Reader, :start_reader, [calc])
    
    Process.monitor(reader)
    receive do
      {:DOWN, _, _, _, _} -> :ok
    end
  end
end
```

### 2.3. Модуль Reader.ex

**Назначение:** Потоковое чтение данных из stdin

```elixir
defmodule Interpolation.Reader do
  def read_loop(calculator_pid, line) do
    case IO.read(:line) do
      :eof ->
        send(calculator_pid, :eof)
        :ok
      input_line ->
        case parse_line(input_line) do
          {:ok, {x, y}} ->
            send(calculator_pid, {:data_point, {x, y}})
            read_loop(calculator_pid, line + 1)
          {:error, _} ->
            IO.puts(:stderr, "Неправильный ввод данных")
            read_loop(calculator_pid, line + 1)
        end
    end
  end
  
  def parse_line(line) do
    line |> String.trim() |> String.split(~r/[;\t ]+/)
    |> case do
      [x_str, y_str] ->
        with {x, ""} <- Float.parse(x_str),
             {y, ""} <- Float.parse(y_str) do
          {:ok, {x, y}}
        else
          _ -> {:error, :invalid_number_format}
        end
      _ -> {:error, :wrong_number_of_values}
    end
  end
end
```

### 2.4. Модуль Calculate.ex

**Назначение:** Управление вычислениями и скользящими окнами

**Ключевые элементы:**

```elixir
defmodule Interpolation.Calculate do
  def start(algorithms, step, window, printer_pid) do
    state = %{
      points: [],
      last_linear_x: nil,
      window_queue: [],      
      algorithms: algorithms,
      step: step,
      window: window,
      printer: printer_pid,
      is_first_window: true,
      last_window_processed: []
    }
    loop(state)
  end
  
  defp loop(state) do
    receive do
      {:data_point, {x, y}} ->
        new_state = add_point_and_process(state, {x, y})
        loop(new_state)
      :eof ->
        do_final_calculations(state)
        send(state.printer, :eof)
    end
  end
  
  defp process_linear(state) do
    sorted = Enum.sort_by(state.points, &elem(&1, 0))
    if length(sorted) >= 2 do
      [{x1, y1}, {x2, _y2}] = Enum.take(sorted, -2)
      if state.last_linear_x == nil do
        send(state.printer, {:result, :linear, x1, y1})
      end
      start_x = state.last_linear_x || x1
      last_x = calc_linear_range(state, start_x, x2, sorted)
      %{state | last_linear_x: last_x}
    else
      state
    end
  end
  
  defp process_window(state, window_algs) do
    current_window = state.window_queue
    window_changed = state.last_window_processed == [] or 
                     current_window != state.last_window_processed
    
    if window_changed do
      sorted_window = Enum.sort_by(current_window, &elem(&1, 0))
      {first_x, _} = List.first(sorted_window)
      {last_x, _} = List.last(sorted_window)
      
      if state.is_first_window do
        # Первое окно: много точек
        Enum.each(sorted_window, fn {x, y} ->
          Enum.each(window_algs, fn alg ->
            send(state.printer, {:result, alg, x, y})
          end)
        end)
        calc_window_many_points(state, sorted_window, first_x, last_x, window_algs)
        %{state | is_first_window: false, last_window_processed: current_window}
      else
        center_x = (first_x + last_x) / 2
        calc_window_single_point(state, sorted_window, center_x, window_algs)
        %{state | last_window_processed: current_window}
      end
    else
      state
    end
  end
end
```

### 2.5. Модуль Algorithms.ex

**Назначение:** Реализация алгоритмов интерполяции

```elixir
defmodule Interpolation.Algorithms do
  def linear(x, points) do
    sorted = Enum.sort_by(points, fn {px, _} -> abs(px - x) end)
    [{x1, y1}, {x2, y2}] = Enum.take(sorted, 2)
    y1 + (y2 - y1) * (x - x1) / (x2 - x1)
  end
  
  def lagrange(x, points) do
    n = length(points) - 1
    Enum.reduce(0..n, 0.0, fn i, acc ->
      {xi, yi} = Enum.at(points, i)
      li = Enum.reduce(0..n, 1.0, fn j, li_acc ->
        if i != j do
          {xj, _} = Enum.at(points, j)
          li_acc * (x - xj) / (xi - xj)
        else
          li_acc
        end
      end)
      acc + yi * li
    end)
  end
  
  def newton(x, points) do
    n = length(points) - 1
    table = build_divided_differences_table(points, n)
    apply_newton_formula(x, points, table, n)
  end
end
```

### 2.6. Модуль Printer.ex

**Назначение:** Вывод результатов в stdout

```elixir
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
```

### 2.7. Механизм общения процессов

Программа использует модель акторов Elixir:

1. **System** создает три процесса через `spawn`:
   - `Reader` - читает из stdin
   - `Calculate` - выполняет вычисления
   - `Printer` - выводит в stdout

2. **Общение через сообщения:**
   - `Reader` → `Calculate`: `{:data_point, {x, y}}`, `:eof`
   - `Calculate` → `Printer`: `{:result, algorithm, x, y}`, `:eof`
   - `System` → `Reader`: мониторинг через `Process.monitor`

3. **Синхронизация:**
   - Каждый процесс работает в бесконечном цикле `receive`
   - Блокировка на `receive` до получения сообщения
   - Асинхронная обработка данных

---

## 3. ВВОД/ВЫВОД ПРОГРАММЫ


### 3.1. Формат аргументов командной строки

```bash
./my_projec [OPTIONS]

Опции:
  --linear, -l          Использовать линейную интерполяцию
  --newton, -n          Использовать интерполяцию Ньютона
  --lagrange            Использовать интерполяцию Лагранжа
  --gauss               Использовать интерполяцию Гаусса (заглушка)
  --step <value>, -s    Шаг дискретизации (по умолчанию 0.5)
  --window <value>, -w  Размер окна для алгоритмов (по умолчанию 4)
  --help, -h            Показать справку
```

### 3.2. Формат входных данных

Входные данные подаются на стандартный ввод в формате:
```
x1 y1
x2 y2
x3 y3
...
```

Разделители: пробел, табуляция (`\t`) или точка с запятой (`;`)

**Требование:** точки должны быть отсортированы по возрастанию x.

**Пример входных данных:**
```
0 0
1 1
2 2
3 3
4 4
```

### 3.3. Формат выходных данных

Выходные данные выводятся в стандартный вывод в формате:
```
algorithm: x y
```

**Пример выходных данных:**
```
linear: 0.0 0.0
linear: 0.5 0.5
linear: 1.0 1.0
linear: 1.5 1.5
```

### 3.4. Примеры использования

#### Пример 1: Линейная интерполяция

```bash
echo -e "0 0\n1 1\n2 2" | ./my_projec --linear --step 0.7
```

**Вывод:**
```
linear: 0.0 0.0
linear: 0.7 0.7
linear: 1.4 1.4
linear: 2.0 2.0
```

#### Пример 2: Интерполяция Ньютона с окном

```bash
echo -e "0 0\n1 1\n2 2\n3 3\n4 4\n5 5\n7 7\n8 8" | ./my_projec --newton --window 4 --step 0.5
```

**Вывод:**
```
newton: 0.0 0.0
newton: 0.5 0.5
newton: 1.0 1.0
newton: 1.5 1.5
newton: 2.0 2.0
newton: 2.5 2.5
newton: 3.0 3.0
newton: 3.5 3.5
newton: 4.0 4.0
newton: 4.5 4.5
newton: 5.0 5.0
newton: 5.5 5.5
newton: 6.0 6.0
newton: 6.5 6.5
newton: 7.0 7.0
newton: 7.5 7.5
newton: 8.0 8.0
```

#### Пример 3: Использование в конвейере

```bash
cat data.txt | ./my_projec --linear --newton --step 0.5 | grep "newton"
```

#### Пример 4: Несколько алгоритмов одновременно

```bash
echo  -e "0 0\n1 1\n2 2\n3 3" | ./my_projec --linear --lagrange --step 0.5
```

**Вывод:**

```
linear: 0.0 0.0
lagrange: 0.0 0.0
lagrange: 1.0 1.0
lagrange: 2.0 2.0
lagrange: 3.0 3.0
linear: 0.5 0.5
lagrange: 0.5 0.5
linear: 1.0 1.0
lagrange: 1.5 1.5
linear: 1.5 1.5
lagrange: 2.5 2.5
linear: 2.0 2.0
linear: 2.5 2.5
linear: 3.0 3.0
```
