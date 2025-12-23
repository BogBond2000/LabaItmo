* **Функциональность:** что делает функция
* **Код:** фрагмент
* **Пояснение:** как работает (коротко и по делу)

---

# Отчёт по коду `LazyRedBlackTree` 

---

## LazyRedBlackTree

### `new/0`

**Функциональность:**
Создаёт пустое дерево.

```elixir
def new(), do: nil
```

**Пояснение:**
Пустое красно-чёрное дерево представляется как `nil`.

---

### `node/2`

**Функциональность:**
Создаёт новый красный узел с ленивым значением.

```elixir
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
```

**Пояснение:**
Новый узел всегда красный. Значение не вычислено, хранится функция `thunk`.

---

### `force/1`

**Функциональность:**
Вычисляет значение узла один раз.

```elixir
def force(%LazyRedBlackTree{computed?: false, thunk: t} = n) do
  v = t.()
  %{n | value: v, thunk: nil, computed?: true}
end

def force(n), do: n
```

**Пояснение:**
Если значение ещё не вычислено — вызывается `thunk`, результат сохраняется.
Если уже вычислено — узел возвращается без изменений.

---

### `insert/3`

**Функциональность:**
Вставляет обычное значение в дерево.

```elixir
def insert(tree, key, value),
  do: insert_lazy(tree, key, fn -> value end)
```

**Пояснение:**
Оборачивает значение в функцию и делегирует ленивой вставке.

---

### `insert_lazy/3`

**Функциональность:**
Вставляет ленивое значение и делает корень чёрным.

```elixir
def insert_lazy(tree, key, thunk) do
  tree
  |> do_insert(key, thunk)
  |> blacken()
end
```

**Пояснение:**
Выполняет рекурсивную вставку и затем принудительно окрашивает корень в чёрный.

---

### `do_insert/3`

**Функциональность:**
Рекурсивно вставляет узел и балансирует дерево.

```elixir
defp do_insert(nil, key, thunk), do: node(key, thunk)

defp do_insert(%LazyRedBlackTree{} = n, key, thunk) do
  n = force(n)

  cond do
    key == n.key ->
      %{n | thunk: thunk, value: nil, computed?: false}

    key < n.key ->
      balance(%{n | left: do_insert(n.left, key, thunk)})

    true ->
      balance(%{n | right: do_insert(n.right, key, thunk)})
  end
end
```

**Пояснение:**
Идёт влево или вправо по ключу. При совпадении ключа значение заменяется.
После вставки применяется балансировка.

---

### `get/2`

**Функциональность:**
Возвращает значение по ключу.

```elixir
def get(tree, key) do
  case do_get(tree, key) do
    nil -> nil
    n -> force(n).value
  end
end
```

**Пояснение:**
Ищет узел и вычисляет значение только при необходимости.

---

### `delete/2`

**Функциональность:**
Удаляет элемент по ключу.

```elixir
def delete(tree, key), do: delete_simple(tree, key)
```

**Пояснение:**
Использует упрощённый алгоритм удаления без сложной балансировки.

---

### `merge/3`

**Функциональность:**
Объединяет два дерева.

```elixir
def merge(tree1, tree2, value_merge_func \\ fn _, v1, v2 -> [v1, v2] |> Enum.uniq() |> Enum.sort() end)
```

**Пояснение:**
Преобразует деревья в списки, объединяет по ключам и собирает новое дерево.

---

### `to_list/1`

**Функциональность:**
Преобразует дерево в отсортированный список.

```elixir
def to_list(tree) do
  do_to_list(tree, [])
end
```

**Пояснение:**
Использует симметричный обход (in-order).

---

### `map/2`

**Функциональность:**
Лениво применяет функцию к значениям дерева.

```elixir
def map(%LazyRedBlackTree{} = n, f) do
  %LazyRedBlackTree{
    n |
    thunk: fn ->
      nn = force(n)
      f.(nn.key, nn.value)
    end,
    left: map(n.left, f),
    right: map(n.right, f),
    computed?: false
  }
end
```

**Пояснение:**
Создаёт новое дерево, где значения вычисляются только при доступе.

---

### `filter/2`

**Функциональность:**
Фильтрует дерево по условию.

```elixir
def filter(%LazyRedBlackTree{} = n, f) do
  n = force(n)
  l = filter(n.left, f)
  r = filter(n.right, f)

  if f.(n.key, n.value), do: %{n | left: l, right: r}, else: merge(l, r)
end
```

**Пояснение:**
Если узел не проходит фильтр — его поддеревья объединяются.

---

### `balance/1`

**Функциональность:**
Поддерживает свойства красно-чёрного дерева.

```elixir
defp balance(n) do
  n =
    if red?(n.right) and not red?(n.left), do: rotate_left(n), else: n

  n =
    if red?(n.left) and red?(n.left.left), do: rotate_right(n), else: n

  if red?(n.left) and red?(n.right), do: flip(n), else: n
end
```

**Функциональность:**
Реализует правила LLRB: повороты и перекраску.

---

## 📦 LazyTreeDict

### `new/0`

**Функциональность:**
Создаёт пустой словарь.

```elixir
def new(), do: %LazyTreeDict{}
```

---

### `put/3`

**Функциональность:**
Добавляет значение по ключу.

```elixir
def put(d, k, v), do: %{d | tree: LazyRedBlackTree.insert(d.tree, k, v)}
```

**Пояснение:**
Обёртка над `LazyRedBlackTree.insert/3`.

---

### `get/2`

**Функциональность:**
Возвращает значение по ключу.

```elixir
def get(d, k), do: LazyRedBlackTree.get(d.tree, k)
```



