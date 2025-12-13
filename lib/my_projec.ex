defmodule LazyRedBlackTree do
  defstruct [:color, :key, :value, :left, :right, :thunk, :computed?]

  @type t :: %LazyRedBlackTree{} | nil

  def new(), do: nil

  defp node(key, thunk) do
    %LazyRedBlackTree{
      color: :red,
      key: key,
      value: nil,
      left: nil,
      right: nil,
      thunk: thunk,
      computed?: false
    }
  end

  def force(%LazyRedBlackTree{computed?: false, thunk: t} = n) do
    v = t.()
    %{n | value: v, thunk: nil, computed?: true}
  end

  def force(n), do: n

  def insert(tree, key, value),
    do: insert_lazy(tree, key, fn -> value end)

  def insert_lazy(tree, key, thunk) do
    tree
    |> do_insert(key, thunk)
    |> blacken()
  end

  defp do_insert(nil, key, thunk), do: node(key, thunk)

  defp do_insert(%LazyRedBlackTree{} = n, key, thunk) do
    n = force(n)

    cond do
      key == n.key ->
        node(key, thunk)

      key < n.key ->
        balance(%{n | left: do_insert(n.left, key, thunk)})

      true ->
        balance(%{n | right: do_insert(n.right, key, thunk)})
    end
  end

  def get(tree, key) do
    case do_get(tree, key) do
      nil -> nil
      n -> force(n).value
    end
  end

  defp do_get(nil, _), do: nil

  defp do_get(%LazyRedBlackTree{} = n, key) do
    n = force(n)

    cond do
      key == n.key -> n
      key < n.key -> do_get(n.left, key)
      true -> do_get(n.right, key)
    end
  end

  def delete(tree, key), do: delete_simple(tree, key)

  defp delete_simple(nil, _), do: nil

  defp delete_simple(%LazyRedBlackTree{} = n, key) do
    n = force(n)

    cond do
      key < n.key ->
        %{n | left: delete_simple(n.left, key)}

      key > n.key ->
        %{n | right: delete_simple(n.right, key)}

      true ->
        merge(n.left, n.right)
    end
  end

  def merge(
        tree1,
        tree2,
        value_merge_func \\ fn _, v1, v2 -> [v1, v2] |> Enum.uniq() |> Enum.sort() end
      ) do
    kv_pairs =
      (to_list(tree1) ++ to_list(tree2))
      |> Enum.group_by(fn {k, _} -> k end, fn {_, v} -> v end)
      |> Enum.map(fn {k, values} ->
        merged =
          Enum.reduce(values, fn v1, v2 ->
            value_merge_func.(k, v1, v2)
          end)

        {k, merged}
      end)
      |> Enum.sort_by(fn {k, _} -> k end)

    Enum.reduce(kv_pairs, nil, fn {k, v}, acc ->
      insert(acc, k, v)
    end)
  end

  def to_stream(tree) do
    tree
    |> to_list()
    |> Enum.filter(&(&1 != nil))
    |> Stream.map(& &1)
  end

  def to_list(tree) do
    do_to_list(tree, [])
  end

  defp do_to_list(nil, acc), do: acc

  defp do_to_list(%LazyRedBlackTree{} = n, acc) do
    n = force(n)
    acc = do_to_list(n.left, acc)
    acc = acc ++ [{n.key, n.value}]
    do_to_list(n.right, acc)
  end

  def map(nil, _), do: nil

  def map(%LazyRedBlackTree{} = n, f) do
    %LazyRedBlackTree{
      n
      | thunk: fn ->
          nn = force(n)
          f.(nn.key, nn.value)
        end,
        left: map(n.left, f),
        right: map(n.right, f),
        computed?: false
    }
  end

  def filter(nil, _), do: nil

  def filter(%LazyRedBlackTree{} = n, f) do
    n = force(n)
    l = filter(n.left, f)
    r = filter(n.right, f)

    if f.(n.key, n.value), do: %{n | left: l, right: r}, else: merge(l, r)
  end

  def foldl(nil, acc, _), do: acc

  def foldl(%LazyRedBlackTree{} = n, acc, f) do
    n = force(n)
    acc = foldl(n.left, acc, f)
    acc = f.(n.key, n.value, acc)
    foldl(n.right, acc, f)
  end

  def foldr(nil, acc, _), do: acc

  def foldr(%LazyRedBlackTree{} = n, acc, f) do
    n = force(n)
    acc = foldr(n.right, acc, f)
    acc = f.(n.key, n.value, acc)
    foldr(n.left, acc, f)
  end

  def size(nil), do: 0
  def size(%LazyRedBlackTree{} = n), do: 1 + size(force(n).left) + size(force(n).right)

  def height(nil), do: 0

  def height(%LazyRedBlackTree{} = n),
    do: 1 + max(height(force(n).left), height(force(n).right))

  def empty?(nil), do: true
  def empty?(_), do: false

  def contains?(t, k), do: get(t, k) != nil

  def keys(t), do: Enum.map(to_list(t), &elem(&1, 0))
  def values(t), do: Enum.map(to_list(t), &elem(&1, 1))

  defp red?(%{color: :red}), do: true
  defp red?(_), do: false

  defp blacken(nil), do: nil
  defp blacken(n), do: %{n | color: :black}

  defp balance(n) do
    n =
      if red?(n.right) and not red?(n.left), do: rotate_left(n), else: n

    n =
      if red?(n.left) and red?(n.left.left), do: rotate_right(n), else: n

    if red?(n.left) and red?(n.right), do: flip(n), else: n
  end

  defp rotate_left(h) do
    x = force(h.right)

    %LazyRedBlackTree{
      color: h.color,
      key: x.key,
      value: x.value,
      left: %{h | right: x.left, color: :red},
      right: x.right,
      computed?: true
    }
  end

  defp rotate_right(h) do
    x = force(h.left)

    %LazyRedBlackTree{
      color: h.color,
      key: x.key,
      value: x.value,
      left: x.left,
      right: %{h | left: x.right, color: :red},
      computed?: true
    }
  end

  defp flip(h) do
    %{h | color: toggle(h.color), left: recolor(h.left), right: recolor(h.right)}
  end

  defp toggle(:red), do: :black
  defp toggle(:black), do: :red
  defp recolor(nil), do: nil
  defp recolor(n), do: %{n | color: toggle(n.color)}

  def valid?(tree), do: check(tree) != :error

  defp check(nil), do: {:ok, 1}

  defp check(%LazyRedBlackTree{} = n) do
    n = force(n)

    if red?(n) and (red?(n.left) or red?(n.right)) do
      :error
    else
      with {:ok, l} <- check(n.left),
           {:ok, r} <- check(n.right),
           true <- l == r do
        {:ok, l + if(n.color == :black, do: 1, else: 0)}
      else
        _ -> :error
      end
    end
  end
end

defmodule LazyTreeDict do
  defstruct tree: nil

  def new(), do: %LazyTreeDict{}

  def put(d, k, v), do: %{d | tree: LazyRedBlackTree.insert(d.tree, k, v)}
  def put_lazy(d, k, f), do: %{d | tree: LazyRedBlackTree.insert_lazy(d.tree, k, f)}
  def get(d, k), do: LazyRedBlackTree.get(d.tree, k)
  def delete(d, k), do: %{d | tree: LazyRedBlackTree.delete(d.tree, k)}
  def has_key?(d, k), do: LazyRedBlackTree.contains?(d.tree, k)
  def size(d), do: LazyRedBlackTree.size(d.tree)
  def empty?(d), do: LazyRedBlackTree.empty?(d.tree)
  def keys(d), do: LazyRedBlackTree.keys(d.tree)
  def values(d), do: LazyRedBlackTree.values(d.tree)
  def to_list(d), do: LazyRedBlackTree.to_list(d.tree)
  def merge(d1, d2), do: %LazyTreeDict{tree: LazyRedBlackTree.merge(d1.tree, d2.tree)}
  def map(d, f), do: %LazyTreeDict{tree: LazyRedBlackTree.map(d.tree, f)}
  def filter(d, f), do: %LazyTreeDict{tree: LazyRedBlackTree.filter(d.tree, f)}
  def foldl(d, acc, f), do: LazyRedBlackTree.foldl(d.tree, acc, f)
  def foldr(d, acc, f), do: LazyRedBlackTree.foldr(d.tree, acc, f)
  def stream(d), do: LazyRedBlackTree.to_stream(d.tree)
end

