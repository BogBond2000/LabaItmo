ExUnit.start()

defmodule LazyRedBlackTreeTest do
  use ExUnit.Case

  alias LazyRedBlackTree

  test "insert and get" do
    tree =
      LazyRedBlackTree.new()
      |> LazyRedBlackTree.insert(:a, 1)
      |> LazyRedBlackTree.insert(:b, 2)
      |> LazyRedBlackTree.insert(:c, 3)

    assert LazyRedBlackTree.get(tree, :a) == 1
    assert LazyRedBlackTree.get(tree, :b) == 2
    assert LazyRedBlackTree.get(tree, :c) == 3
    assert LazyRedBlackTree.get(tree, :d) == nil
  end

  test "to_list and to_stream" do
    tree =
      LazyRedBlackTree.new()
      |> LazyRedBlackTree.insert(:b, 2)
      |> LazyRedBlackTree.insert(:a, 1)
      |> LazyRedBlackTree.insert(:c, 3)

    assert LazyRedBlackTree.to_list(tree) == [a: 1, b: 2, c: 3]

    stream = LazyRedBlackTree.to_stream(tree)
    assert Enum.to_list(stream) == [a: 1, b: 2, c: 3]
  end

  test "lazy insertion" do
    {:ok, counter} = Agent.start_link(fn -> 0 end)

    tree =
      LazyRedBlackTree.new()
      |> LazyRedBlackTree.insert_lazy(:a, fn ->
        Agent.update(counter, &(&1 + 1))
        42
      end)

    # значение ещё не вычислялось
    assert Agent.get(counter, & &1) == 0

    # вычисляется при доступе
    assert LazyRedBlackTree.get(tree, :a) == 42
    assert Agent.get(counter, & &1) == 1
  end

  test "map, filter, fold" do
    tree =
      LazyRedBlackTree.new()
      |> LazyRedBlackTree.insert(1, 2)
      |> LazyRedBlackTree.insert(2, 4)
      |> LazyRedBlackTree.insert(3, 6)

    mapped = LazyRedBlackTree.map(tree, fn _k, v -> v * 2 end)
    assert LazyRedBlackTree.to_list(mapped) == [{1, 4}, {2, 8}, {3, 12}]

    filtered = LazyRedBlackTree.filter(tree, fn k, _ -> k > 1 end)
    assert LazyRedBlackTree.to_list(filtered) == [{2, 4}, {3, 6}]

    sum = LazyRedBlackTree.foldl(tree, 0, fn _, v, acc -> acc + v end)
    assert sum == 12
  end

  test "tree properties" do
    tree =
      Enum.reduce(1..100, LazyRedBlackTree.new(), fn i, acc ->
        LazyRedBlackTree.insert(acc, i, i)
      end)

    assert LazyRedBlackTree.valid?(tree)
    assert LazyRedBlackTree.size(tree) == 100
    assert LazyRedBlackTree.height(tree) > 0
  end
end

defmodule LazyTreeDictTest do
  use ExUnit.Case

  alias LazyTreeDict

  test "dictionary operations" do
    dict =
      LazyTreeDict.new()
      |> LazyTreeDict.put(:name, "Alice")
      |> LazyTreeDict.put(:age, 30)

    assert LazyTreeDict.get(dict, :name) == "Alice"
    assert LazyTreeDict.get(dict, :age) == 30
    assert LazyTreeDict.get(dict, :unknown) == nil
  end

  test "delete from dictionary" do
    dict =
      LazyTreeDict.new()
      |> LazyTreeDict.put(:name, "Alice")
      |> LazyTreeDict.delete(:name)

    assert LazyTreeDict.get(dict, :name) == nil
  end

  test "lazy dictionary operations" do
    {:ok, counter} = Agent.start_link(fn -> 0 end)

    dict =
      LazyTreeDict.new()
      |> LazyTreeDict.put_lazy(:x, fn ->
        Agent.update(counter, &(&1 + 1))
        99
      end)

    assert Agent.get(counter, & &1) == 0
    assert LazyTreeDict.get(dict, :x) == 99
    assert Agent.get(counter, & &1) == 1
  end

  test "dictionary stream" do
    dict =
      LazyTreeDict.new()
      |> LazyTreeDict.put(:b, 2)
      |> LazyTreeDict.put(:a, 1)
      |> LazyTreeDict.put(:c, 3)

    assert Enum.to_list(LazyTreeDict.stream(dict)) == [a: 1, b: 2, c: 3]
  end
end
