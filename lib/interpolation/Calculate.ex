# calculate.ex
defmodule Interpolation.Calculate do
  def start(algorithms, step, window, printer_pid) do
    state = %{
      points: [],
      last_linear_x: nil,
      window_queue: [],  # Очередь для скользящего окна
      algorithms: algorithms,
      step: step,
      window: window,
      printer: printer_pid,
      is_first_window: true,
      last_window_processed: []  # Последнее обработанное окно для отслеживания скольжения
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

  # Добавляем точку и обрабатываем
  defp add_point_and_process(state, {x, y}) do
    new_points = [{x, y} | state.points] |> Enum.sort_by(&elem(&1, 0))
    
    # Обновляем очередь окна (последние window точек)
    new_window_queue = new_points |> Enum.take(-state.window) |> Enum.sort_by(&elem(&1, 0))
    
    updated_state = %{state | 
      points: new_points,
      window_queue: new_window_queue
    }
    
    # Обрабатываем линейную интерполяцию
    state_after_linear = if :linear in state.algorithms and length(new_points) >= 2 do
      process_linear(updated_state)
    else
      updated_state
    end
    
    # Обрабатываем алгоритмы с окном
    window_algs = Enum.filter(state.algorithms, &(&1 != :linear))
    # Для алгоритмов с окном нужно минимум window точек
    min_points_for_window = if length(window_algs) > 0, do: state.window, else: 0
    if length(window_algs) > 0 and length(new_window_queue) >= min_points_for_window do
      process_window(state_after_linear, window_algs)
    else
      state_after_linear
    end
  end

  # Обработка линейной интерполяции
  defp process_linear(state) do
    sorted = Enum.sort_by(state.points, &elem(&1, 0))
    
    if length(sorted) >= 2 do
      [{x1, y1}, {x2, _y2}] = Enum.take(sorted, -2)
      
      # Выводим первую исходную точку
      if state.last_linear_x == nil do
        send(state.printer, {:result, :linear, x1, y1})
      end
      
      # Вычисляем промежуточные точки
      start_x = state.last_linear_x || x1
      last_x = calc_linear_range(state, start_x, x2, sorted)
      
      %{state | last_linear_x: last_x}
    else
      state
    end
  end

  # Вычисление точек для линейной интерполяции
  defp calc_linear_range(state, start_x, end_x, all_points) do
    next_x = if state.last_linear_x == nil, do: start_x + state.step, else: start_x + state.step
    
    if next_x < end_x do
      # Находим две ближайшие точки
      window_pts = all_points
                  |> Enum.sort_by(fn {px, _} -> abs(px - next_x) end)
                  |> Enum.take(2)
                  |> Enum.sort_by(&elem(&1, 0))
      
      if length(window_pts) >= 2 do
        y = Interpolation.Algorithms.linear(next_x, window_pts)
        send(state.printer, {:result, :linear, next_x, y})
      end
      
      calc_linear_range(%{state | last_linear_x: next_x}, next_x, end_x, all_points)
    else
      state.last_linear_x || start_x
    end
  end

  # Обработка алгоритмов с окном
  defp process_window(state, window_algs) do
    current_window = state.window_queue
    
    # Проверяем, изменилось ли окно (скольжение)
    # Для первого окна last_window_processed пустой, поэтому всегда обрабатываем
    window_changed = state.last_window_processed == [] or current_window != state.last_window_processed
    
    if window_changed do
      sorted_window = Enum.sort_by(current_window, &elem(&1, 0))
      {first_x, _} = List.first(sorted_window)
      {last_x, _} = List.last(sorted_window)
      
      if state.is_first_window do
        # Первое окно: выводим исходные точки, затем вычисляем много точек
        # Выводим исходные точки окна
        Enum.each(sorted_window, fn {x, y} ->
          Enum.each(window_algs, fn alg ->
            send(state.printer, {:result, alg, x, y})
          end)
        end)
        
        # Вычисляем много точек от начала до конца с шагом
        calc_window_many_points(state, sorted_window, first_x, last_x, window_algs)
        %{state | is_first_window: false, last_window_processed: current_window}
      else
        # Промежуточное окно: вычисляем одну точку в центре
        center_x = (first_x + last_x) / 2
        calc_window_single_point(state, sorted_window, center_x, window_algs)
        %{state | last_window_processed: current_window}
      end
    else
      state
    end
  end

  # Вычисление множества точек для окна (первое окно)
  defp calc_window_many_points(state, window_points, start_x, end_x, algorithms) do
    calc_window_many_points_rec(state, window_points, start_x, end_x, algorithms)
  end

  defp calc_window_many_points_rec(state, window_points, current_x, end_x, algorithms) do
    if current_x <= end_x do
      Enum.each(algorithms, fn alg ->
        y = calc_algorithm(alg, current_x, window_points, state.window)
        send(state.printer, {:result, alg, current_x, y})
      end)
      
      next_x = current_x + state.step
      if next_x <= end_x do
        calc_window_many_points_rec(state, window_points, next_x, end_x, algorithms)
      end
    end
  end

  # Вычисление одной точки в центре (промежуточные окна)
  defp calc_window_single_point(state, window_points, center_x, algorithms) do
    Enum.each(algorithms, fn alg ->
      y = calc_algorithm(alg, center_x, window_points, state.window)
      send(state.printer, {:result, alg, center_x, y})
    end)
  end

  # Финальные вычисления при EOF
  defp do_final_calculations(state) do
    window_algs = Enum.filter(state.algorithms, &(&1 != :linear))
    has_linear = :linear in state.algorithms
    
    # Обработка алгоритмов с окном
    if length(window_algs) > 0 and length(state.points) > 0 do
      # Последнее окно: вычисляем точки после последней входной точки
      if length(state.window_queue) >= state.window do
        sorted_window = Enum.sort_by(state.window_queue, &elem(&1, 0))
        {last_x, _} = List.last(sorted_window)
        end_x = last_x + state.step * 3
        
        calc_final_window_points(state, sorted_window, last_x, end_x, window_algs)
      end
    end
    
    # Финальные вычисления для линейной интерполяции
    if has_linear and length(state.points) >= 2 do
      sorted_points = Enum.sort_by(state.points, &elem(&1, 0))
      {last_x, last_y} = List.last(sorted_points)
      
      # Выводим последнюю исходную точку
      send(state.printer, {:result, :linear, last_x, last_y})
      
      # Вычисляем оставшиеся точки
      start_x = state.last_linear_x || last_x
      if start_x < last_x + state.step do
        calc_linear_range(state, start_x, last_x + state.step * 2, sorted_points)
      end
    end
  end

  # Вычисление финальных точек для последнего окна
  defp calc_final_window_points(state, window_points, start_x, end_x, algorithms) do
    next_x = start_x + state.step
    
    if next_x <= end_x do
      Enum.each(algorithms, fn alg ->
        y = calc_algorithm(alg, next_x, window_points, state.window)
        send(state.printer, {:result, alg, next_x, y})
      end)
      
      calc_final_window_points(state, window_points, next_x, end_x, algorithms)
    end
  end

  # Вычисление значения по алгоритму
  defp calc_algorithm(algorithm, x, points, window) do
    window_size = case algorithm do
      :linear -> min(2, window)
      _ -> min(window, length(points))
    end

    window_points = points
                   |> Enum.take(window_size)
                   |> Enum.sort_by(&elem(&1, 0))

    case algorithm do
      :linear -> Interpolation.Algorithms.linear(x, window_points)
      :lagrange -> Interpolation.Algorithms.lagrange(x, window_points)
      :newton -> Interpolation.Algorithms.newton(x, window_points)
      :gauss -> x
    end
  end
end
