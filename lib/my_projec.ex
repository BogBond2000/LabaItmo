defmodule MyProjectTest do
  use ExUnit.Case
  doctest MyProject

  describe "Problem 6 - Sum square difference" do
    test "monolithic recursion" do
      assert MyProject.problem6_monolithic_recursion(10) == 2640
      assert MyProject.problem6_monolithic_recursion(100) == 25_164_150
    end

    test "modular implementation" do
      assert MyProject.problem6_modular(10) == 2640
      assert MyProject.problem6_modular(100) == 25_164_150
    end

    test "comprehension syntax" do
      assert MyProject.problem6_comprehension(10) == 2640
    end
  end

  describe "Problem 2 - Even Fibonacci numbers" do
    test "tail recursion" do
      assert MyProject.problem2_tail_recursion(4_000_000) == 4_613_732
    end

    test "naive recursion" do
      assert MyProject.problem2_naive_recursion(100) == 44
    end

    test "stream implementation" do
      assert MyProject.problem2_stream(100) == 44
      assert MyProject.problem2_stream(4_000_000) == 4_613_732
    end

    test "modular implementation" do
      assert MyProject.problem2_modular(100) == 44
    end
  end

  describe "Fibonacci variants" do
    test "tail recursive fibonacci" do
      assert MyProject.fibonachi(10) == 55
    end

    test "naive recursive fibonacci" do
      assert MyProject.fibonachi_recursion(10) == 55
    end
  end
end
