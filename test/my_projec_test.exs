defmodule LazyRedBlackTreePBT do
  use ExUnit.Case
  use ExUnitProperties

  alias LazyRedBlackTree

  #
  # Генераторы
  #
  defp kv_list do
  list_of({integer(), integer()}, max_length: 200)
  end

 defp build_tree(kvs) do
  Enum.reduce(kvs, LazyRedBlackTree.new(), fn {k, v}, acc ->
    LazyRedBlackTree.insert(acc, k, v)
  end)
 end

 defp tree_gen do
  kv_list()
  |> map(fn kvs -> build_tree(kvs) end)
 end

  #
  # Свойства
  #

  property "tree is always a valid red-black tree" do
    check all(kvs <- kv_list()) do
      tree = build_tree(kvs)
      assert LazyRedBlackTree.valid?(tree)
    end
  end

  property "in-order traversal is sorted by keys" do
    check all(kvs <- kv_list()) do
      tree = build_tree(kvs)

      keys =
        LazyRedBlackTree.to_list(tree)
        |> Enum.map(&elem(&1, 0))

      assert keys == Enum.sort(keys)
    end
  end

  property "get returns the last inserted value for a key" do
    check all(
            kvs <- kv_list(),
            {k, v} <- {integer(), integer()}
          ) do
      tree =
        kvs
        |> build_tree()
        |> LazyRedBlackTree.insert(k, v)

      assert LazyRedBlackTree.get(tree, k) == v
    end
  end
  property "merge has identity element (empty tree)" do
  check all(tree <- tree_gen()) do
    empty = LazyRedBlackTree.new()

    assert LazyRedBlackTree.to_list(
             LazyRedBlackTree.merge(empty, tree)
           ) ==
           LazyRedBlackTree.to_list(tree)

    assert LazyRedBlackTree.to_list(
             LazyRedBlackTree.merge(tree, empty)
           ) ==
           LazyRedBlackTree.to_list(tree)
    end
  end
  property "merge is associative (monoid law)" do
  check all(
          t1 <- tree_gen(),
          t2 <- tree_gen(),
          t3 <- tree_gen()
        ) do
    left =
      LazyRedBlackTree.merge(
        LazyRedBlackTree.merge(t1, t2),
        t3
      )
      |> LazyRedBlackTree.to_list()

    right =
      LazyRedBlackTree.merge(
        t1,
        LazyRedBlackTree.merge(t2, t3)
      )
      |> LazyRedBlackTree.to_list()

    assert left == right
    end
  end

  property "size equals number of unique keys" do
    check all(kvs <- kv_list()) do
      tree = build_tree(kvs)

      unique_keys =
        kvs
        |> Enum.map(&elem(&1, 0))
        |> Enum.uniq()
        |> length()

      assert LazyRedBlackTree.size(tree) == unique_keys
    end
  end

  property "delete removes the key" do
    check all(
            kvs <- kv_list(),
            k <- integer()
          ) do
      tree = build_tree(kvs)
      tree2 = LazyRedBlackTree.delete(tree, k)

      assert LazyRedBlackTree.get(tree2, k) == nil
    end
  end

  property "map preserves keys" do
    check all(kvs <- kv_list()) do
      tree = build_tree(kvs)

      mapped =
        LazyRedBlackTree.map(tree, fn _k, v -> v * 10 end)

      assert LazyRedBlackTree.keys(mapped) ==
               LazyRedBlackTree.keys(tree)
    end
  end

  property "filter only keeps keys satisfying predicate" do
    check all(kvs <- kv_list()) do
      tree = build_tree(kvs)

      filtered =
        LazyRedBlackTree.filter(tree, fn k, _v -> rem(k, 2) == 0 end)

      assert Enum.all?(
               LazyRedBlackTree.keys(filtered),
               fn k -> rem(k, 2) == 0 end
             )
    end
  end

  property "foldl equals Enum.reduce over to_list" do
    check all(kvs <- kv_list()) do
      tree = build_tree(kvs)

      t_sum =
        LazyRedBlackTree.foldl(tree, 0, fn _, v, acc -> acc + v end)

      l_sum =
        tree
        |> LazyRedBlackTree.to_list()
        |> Enum.map(&elem(&1, 1))
        |> Enum.sum()

      assert t_sum == l_sum
    end
  end

  test "single element tree" do
    tree = LazyRedBlackTree.insert(nil, :a, 1)

    assert LazyRedBlackTree.get(tree, :a) == 1
    assert LazyRedBlackTree.size(tree) == 1
    assert LazyRedBlackTree.height(tree) == 1
    assert LazyRedBlackTree.valid?(tree)
  end

  test "two elements ordering" do
    tree =
      LazyRedBlackTree.new()
      |> LazyRedBlackTree.insert(2, :b)
      |> LazyRedBlackTree.insert(1, :a)

    assert LazyRedBlackTree.to_list(tree) == [{1, :a}, {2, :b}]
    assert LazyRedBlackTree.valid?(tree)
  end

  test "insert overwrites value for same key" do
    tree =
      LazyRedBlackTree.new()
      |> LazyRedBlackTree.insert(:a, 1)
      |> LazyRedBlackTree.insert(:a, 2)

    assert LazyRedBlackTree.size(tree) == 1
    assert LazyRedBlackTree.get(tree, :a) == 2
    assert LazyRedBlackTree.to_list(tree) == [a: 2]
    assert LazyRedBlackTree.valid?(tree)
  end

  test "delete removes element from small tree" do
    tree =
      LazyRedBlackTree.new()
      |> LazyRedBlackTree.insert(1, :a)
      |> LazyRedBlackTree.insert(2, :b)
      |> LazyRedBlackTree.insert(3, :c)

    tree2 = LazyRedBlackTree.delete(tree, 2)

    assert LazyRedBlackTree.get(tree2, 2) == nil
    assert LazyRedBlackTree.to_list(tree2) == [{1, :a}, {3, :c}]
    assert LazyRedBlackTree.valid?(tree2)
  end
end
