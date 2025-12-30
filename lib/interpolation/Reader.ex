defmodule Interpolation.Reader do
  def start_reader(calculator_pid) do
    read_loop(calculator_pid, 1)
  end

  def read_loop(calculator_pid,line) do
    case IO.read(:line) do
      :eof ->
        send(calculator_pid,:eof)
        :ok
      input_line ->
        case parse_line(input_line) do
          {:ok, {x,y}}->
            send(calculator_pid,{:data_point,{x,y}})
            read_loop(calculator_pid,line+1)
          {:error,_} ->
            IO.puts(:stderr, "Неправильный ввод данных для x y, возможные знаки-разделители: ; \\t")
            read_loop(calculator_pid,line+1)
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

         _ ->
           {:error, :wrong_number_of_values}
       end
  end
end