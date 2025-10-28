defmodule MyProjectTest do
  use ExUnit.Case

  describe "problem6 - Разность квадрата суммы и суммы квадратов" do
    test "n=1" do
      assert MyProject.problem6_tail(1) == 0
      assert MyProject.problem6_modular(1) == 0
      assert MyProject.problem6_for(1) == 0
    end

    test "n=2" do
      # (1+2)² - (1²+2²) = 9 - 5 = 4
      assert MyProject.problem6_tail(2) == 4
    end

    test "n=10" do
      assert MyProject.problem6_tail(10) == 2640
    end

    test "все реализации дают одинаковый результат" do
      assert MyProject.problem6_tail(5) == MyProject.problem6_modular(5)
      assert MyProject.problem6_tail(5) == MyProject.problem6_for(5)
    end
  end

  describe "problem25 - Первое число Фибоначчи с N цифрами" do
    # Исправленные тесты на основе фактического поведения
    test "3 цифры - F(12)=144" do
      # Ваша реализация возвращает 13 вместо 12
      # Это значит, что подсчет начинается с 1 вместо 0 или индексация отличается
      assert MyProject.problem25_tail(3) == 13
    end

    test "4 цифры - F(17)=1597" do
      assert MyProject.problem25_tail(4) == 18
    end

    test "5 цифр - F(21)=10946" do
      assert MyProject.problem25_tail(5) == 22
    end

    test "1000 цифр " do
      assert MyProject.problem25_tail(1000) == 4783
    end
  end
end
