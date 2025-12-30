#ExUnit.start()
#
#defmodule LazyRedBlackTreePBT do
#  use ExUnit.Case
#  use ExUnitProperties
#
#  alias LazyRedBlackTree
#
#  #
#  # Генераторы
#  #
#  defp kv_list do
#    list_of({integer(), integer()}, max_length: 200)
#  end
#
#  defp build_tree(kvs) do
#    Enum.reduce(kvs, LazyRedBlackTree.new(), fn {k, v}, acc ->
#      LazyRedBlackTree.insert(acc, k, v)
#    end)
#  end
#
#  #
#  # Свойства
#  #
#
#  property "tree is always a valid red-black tree" do
#    check all(kvs <- kv_list()) do
#      tree = build_tree(kvs)
#      assert LazyRedBlackTree.valid?(tree)
#    end
#  end
#
#  property "in-order traversal is sorted by keys" do
#    check all(kvs <- kv_list()) do
#      tree = build_tree(kvs)
#
#      keys =
#        LazyRedBlackTree.to_list(tree)
#        |> Enum.map(&elem(&1, 0))
#
#      assert keys == Enum.sort(keys)
#    end
#  end
#
#  property "get returns the last inserted value for a key" do
#    check all(
#            kvs <- kv_list(),
#            {k, v} <- {integer(), integer()}
#          ) do
#      tree =
#        kvs
#        |> build_tree()
#        |> LazyRedBlackTree.insert(k, v)
#
#      assert LazyRedBlackTree.get(tree, k) == v
#    end
#  end
#
#  property "size equals number of unique keys" do
#    check all(kvs <- kv_list()) do
#      tree = build_tree(kvs)
#
#      unique_keys =
#        kvs
#        |> Enum.map(&elem(&1, 0))
#        |> Enum.uniq()
#        |> length()
#
#      assert LazyRedBlackTree.size(tree) == unique_keys
#    end
#  end
#
#  property "delete removes the key" do
#    check all(
#            kvs <- kv_list(),
#            k <- integer()
#          ) do
#      tree = build_tree(kvs)
#      tree2 = LazyRedBlackTree.delete(tree, k)
#
#      assert LazyRedBlackTree.get(tree2, k) == nil
#    end
#  end
#
#  property "map preserves keys" do
#    check all(kvs <- kv_list()) do
#      tree = build_tree(kvs)
#
#      mapped =
#        LazyRedBlackTree.map(tree, fn _k, v -> v * 10 end)
#
#      assert LazyRedBlackTree.keys(mapped) ==
#               LazyRedBlackTree.keys(tree)
#    end
#  end
#
#  property "filter only keeps keys satisfying predicate" do
#    check all(kvs <- kv_list()) do
#      tree = build_tree(kvs)
#
#      filtered =
#        LazyRedBlackTree.filter(tree, fn k, _v -> rem(k, 2) == 0 end)
#
#      assert Enum.all?(
#               LazyRedBlackTree.keys(filtered),
#               fn k -> rem(k, 2) == 0 end
#             )
#    end
#  end
#
#  property "foldl equals Enum.reduce over to_list" do
#    check all(kvs <- kv_list()) do
#      tree = build_tree(kvs)
#
#      t_sum =
#        LazyRedBlackTree.foldl(tree, 0, fn _, v, acc -> acc + v end)
#
#      l_sum =
#        tree
#        |> LazyRedBlackTree.to_list()
#        |> Enum.map(&elem(&1, 1))
#        |> Enum.sum()
#
#      assert t_sum == l_sum
#    end
#  end
#end
#
#defmodule LazyRedBlackTreeTest do
#  use ExUnit.Case
#
#  alias LazyRedBlackTree
#
#  test "insert and get" do
#    tree =
#      LazyRedBlackTree.new()
#      |> LazyRedBlackTree.insert(:a, 1)
#      |> LazyRedBlackTree.insert(:b, 2)
#      |> LazyRedBlackTree.insert(:c, 3)
#
#    assert LazyRedBlackTree.get(tree, :a) == 1
#    assert LazyRedBlackTree.get(tree, :b) == 2
#    assert LazyRedBlackTree.get(tree, :c) == 3
#    assert LazyRedBlackTree.get(tree, :d) == nil
#  end
#
#  test "to_list and to_stream" do
#    tree =
#      LazyRedBlackTree.new()
#      |> LazyRedBlackTree.insert(:b, 2)
#      |> LazyRedBlackTree.insert(:a, 1)
#      |> LazyRedBlackTree.insert(:c, 3)
#
#    assert LazyRedBlackTree.to_list(tree) == [a: 1, b: 2, c: 3]
#
#    stream = LazyRedBlackTree.to_stream(tree)
#    assert Enum.to_list(stream) == [a: 1, b: 2, c: 3]
#  end
#
#  test "lazy insertion" do
#    {:ok, counter} = Agent.start_link(fn -> 0 end)
#
#    tree =
#      LazyRedBlackTree.new()
#      |> LazyRedBlackTree.insert_lazy(:a, fn ->
#        Agent.update(counter, &(&1 + 1))
#        42
#      end)
#
#    # значение ещё не вычислялось
#    assert Agent.get(counter, & &1) == 0
#
#    # вычисляется при доступе
#    assert LazyRedBlackTree.get(tree, :a) == 42
#    assert Agent.get(counter, & &1) == 1
#  end
#
#  test "map, filter, fold" do
#    tree =
#      LazyRedBlackTree.new()
#      |> LazyRedBlackTree.insert(1, 2)
#      |> LazyRedBlackTree.insert(2, 4)
#      |> LazyRedBlackTree.insert(3, 6)
#
#    mapped = LazyRedBlackTree.map(tree, fn _k, v -> v * 2 end)
#    assert LazyRedBlackTree.to_list(mapped) == [{1, 4}, {2, 8}, {3, 12}]
#
#    filtered = LazyRedBlackTree.filter(tree, fn k, _ -> k > 1 end)
#    assert LazyRedBlackTree.to_list(filtered) == [{2, 4}, {3, 6}]
#
#    sum = LazyRedBlackTree.foldl(tree, 0, fn _, v, acc -> acc + v end)
#    assert sum == 12
#  end
#
#  test "tree properties" do
#    tree =
#      Enum.reduce(1..100, LazyRedBlackTree.new(), fn i, acc ->
#        LazyRedBlackTree.insert(acc, i, i)
#      end)
#
#    assert LazyRedBlackTree.valid?(tree)
#    assert LazyRedBlackTree.size(tree) == 100
#    assert LazyRedBlackTree.height(tree) > 0
#  end
#end
#
#defmodule LazyTreeDictTest do
#  use ExUnit.Case
#
#  alias LazyTreeDict
#
#  test "dictionary operations" do
#    dict =
#      LazyTreeDict.new()
#      |> LazyTreeDict.put(:name, "Alice")
#      |> LazyTreeDict.put(:age, 30)
#
#    assert LazyTreeDict.get(dict, :name) == "Alice"
#    assert LazyTreeDict.get(dict, :age) == 30
#    assert LazyTreeDict.get(dict, :unknown) == nil
#  end
#
#  test "delete from dictionary" do
#    dict =
#      LazyTreeDict.new()
#      |> LazyTreeDict.put(:name, "Alice")
#      |> LazyTreeDict.delete(:name)
#
#    assert LazyTreeDict.get(dict, :name) == nil
#  end
#
#  test "lazy dictionary operations" do
#    {:ok, counter} = Agent.start_link(fn -> 0 end)
#
#    dict =
#      LazyTreeDict.new()
#      |> LazyTreeDict.put_lazy(:x, fn ->
#        Agent.update(counter, &(&1 + 1))
#        99
#      end)
#
#    assert Agent.get(counter, & &1) == 0
#    assert LazyTreeDict.get(dict, :x) == 99
#    assert Agent.get(counter, & &1) == 1
#  end
#
#  test "dictionary stream" do
#    dict =
#      LazyTreeDict.new()
#      |> LazyTreeDict.put(:b, 2)
#      |> LazyTreeDict.put(:a, 1)
#      |> LazyTreeDict.put(:c, 3)
#
#    assert Enum.to_list(LazyTreeDict.stream(dict)) == [a: 1, b: 2, c: 3]
#  end
#end
