defmodule PriorityQueue do

  @compile :native
  @compile {:hipe, [:o3]}

  @moduledoc """
  Priority Queues in Elixir

  From Wikipedia: A priority queue is an abstract data type which is like
  a regular queue or stack data structure, but where additionally each
  element has a "priority" associated with it. In a priority queue, an
  element with high priority is served before an element with low
  priority. If two elements have the same priority, they are served
  according to their order in the queue.

  While priority queues are often implemented with heaps, they are
  conceptually distinct from heaps. A priority queue is an abstract
  concept like "a list" or "a map"; just as a list can be implemented with
  a linked list or an array, a priority queue can be implemented with a
  heap or a variety of other methods.

  In computer science, a heap is a specialized tree-based data structure
  that satisfies the heap property:
  *  If A is a parent node of B, then the key of node A is ordered with
     respect to the key of node B, with the same ordering applying
     across the heap.

  a) Either the keys of parent nodes are always greater than or equal to
     those of the children and the highest key is in the root node (this
     kind of heap is called max heap)
  b) or the keys of parent nodes are less than or equal to those of the
     children and the lowest key is in the root node (min heap)

  The heap is one maximally efficient implementation of a Priority Queue

  %% heap :: nil | {Item, Value, [heap()]}
  """

  @type key :: any
  @type value :: any
  @type element :: {key, value}


  @type t :: %__MODULE__{size: non_neg_integer, heap: term}
  defstruct size: 0, heap: nil

  #
  # Public interface: priority queues
  #

  @doc """
  Return new priority queue with minimum element removed

  iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> PriorityQueue.delete_min |> PriorityQueue.size
  3
  """
  @spec delete_min(t) :: t
  def delete_min(%PriorityQueue{size: 0, heap: nil}), do: nil
  def delete_min(pq = %PriorityQueue{size: n, heap: heap}) do
    %{pq | size: n - 1, heap: PairingHeap.delete_min(heap)}
  end

  @doc """
  True iff argument is an empty priority queue

      iex> PriorityQueue.new |> PriorityQueue.empty?
      true

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> PriorityQueue.empty?
      false
  """
  @spec empty?(t) :: boolean
  def empty?(%PriorityQueue{size: 0, heap: nil}), do: true
  def empty?(_), do: false

  @doc "Construct priority queue from list"
  def from_list(l) do
    Enum.into(l, PriorityQueue.new  )
    # Enum.reduce(l, new(), fn
    #   ({key, value}, pq)  -> put(pq, key, value)
    #   ({key}, pq)         -> put(pq, key, nil)
    #   (key, pq)           -> put(pq, key, nil)
    # end)
  end

  @doc """
  Merge two priority queues

      iex> PriorityQueue.merge( Enum.into([4,{8}], PriorityQueue.new), Enum.into([3,{1, "first"}], PriorityQueue.new)) |> PriorityQueue.to_list
      [{1, "first"}, {3, nil}, {4, nil}, {8, nil}]
  """
  @spec merge(t, t) :: t
  def merge(pq = %PriorityQueue{size: m, heap: heap0}, %PriorityQueue{size: n, heap: heap1}) do
    %{pq | size: m + n, heap: PairingHeap.meld(heap0, heap1)}
  end

  @doc """
  Return the minimum element

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> PriorityQueue.min
      {1, "first"}
  """
  @spec min(t) :: element | :error
  def min(%PriorityQueue{heap: heap}), do: PairingHeap.min(heap)

  @doc """
  Returns new, empty priority queue
  """
  def new, do: %PriorityQueue{}

  @doc """
  Returns the min item, as well as the queue without the min item
  Equivalent to:
    {min(pq), delete_min(pq)}

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> PriorityQueue.pop |> elem(0)
      {1, "first"}

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> PriorityQueue.pop |> elem(1) |> PriorityQueue.to_list
      [{3, nil}, {4, nil}, {8, nil}]
  """
  @spec pop(t) :: {element, t}
  def pop(pq = %PriorityQueue{size: n, heap: heap}) do
    {e, heap} = PairingHeap.pop(heap)
    {e, %{pq | size: n - 1, heap: heap}}
  end

  @doc """
  Add (insert) element key,value to priority queue
  Pass key/value either as two arguments, or as a tuple {key,value}

      iex> PriorityQueue.new |> PriorityQueue.put(1) |> PriorityQueue.to_list
      [{1, nil}]

      iex> PriorityQueue.new |> PriorityQueue.put(1, "first") |> PriorityQueue.to_list
      [{1, "first"}]

      iex> PriorityQueue.new |> PriorityQueue.put({1, "first"}) |> PriorityQueue.to_list
      [{1, "first"}]
  """
  @spec put(t, {key, value}) :: t
  @spec put(t, key, value | none) :: t
  def put(pq = %PriorityQueue{ size: n, heap: heap }, {key, value}) do
    %{pq | size: n + 1, heap: PairingHeap.put(heap, key, value)}
  end
  def put(pq = %PriorityQueue{ size: n, heap: heap }, key, value \\ nil) do
    %{pq | size: n + 1, heap: PairingHeap.put(heap, key, value)}
  end

  @doc """
  Number of elements in queue

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> PriorityQueue.size
      4
  """
  @spec size(t) :: non_neg_integer
  def size(%PriorityQueue{size: n}), do: n

  @doc """
  Heap sort a list

      iex> PriorityQueue.sort([4,8,3,1])
      [1, 3, 4, 8]
  """
  @spec sort(list) :: list
  def sort(list_to_sort) do
    Enum.into(list_to_sort, PriorityQueue.new)
    |> keys
  end

  @doc """
  Retrieve elements from priority queue as a list in sorted order

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> PriorityQueue.to_list
      [{1, "first"}, {3, nil}, {4, nil}, {8, nil}]
  """
  @spec to_list(t) :: list
  def to_list(%PriorityQueue{size: 0, heap: nil}), do: []
  def to_list(pq) do
    [min(pq) | to_list(delete_min(pq))]
  end

  @doc """
  Retrieve keys from priority queue as a list in sorted order (may have duplicates)

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> PriorityQueue.keys
      [1, 3, 4, 8]
  """
  @spec keys(t) :: list
  def keys(%PriorityQueue{size: 0, heap: nil}), do: []
  def keys(pq) do
    {key, _value} = min(pq)
    [key | keys(delete_min(pq))]
  end

  @doc """
  Retrieve values from priority queue as a list in sorted order

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> PriorityQueue.values
      ["first", nil, nil, nil]
  """
  @spec values(t) :: list
  def values(%PriorityQueue{size: 0, heap: nil}), do: []
  def values(pq) do
    {_k, v} = min(pq)
    [v | values(delete_min(pq))]
  end

end

defimpl Collectable, for: PriorityQueue do

  def empty(_pq) do
    PriorityQueue.new
  end

  @doc """
  Implements 'into' for PriorityQueue

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> PriorityQueue.size
      4
  """
  def into(original) do
    {original, fn
      pq, {:cont, {k, v}} -> PriorityQueue.put(pq, k, v)
      pq, {:cont, {k}} -> PriorityQueue.put(pq, k, nil)
      pq, {:cont, k} -> PriorityQueue.put(pq, k, nil)
      pq, :done -> pq
      _, :halt -> :ok
    end}
  end
end

defimpl Enumerable, for: PriorityQueue do

  @doc """
  Implements 'reduce' for PriorityQueue

  Currently traverses in priority order. This may change in the future.
  DO NOT RELY ON TRAVERSAL ORDER

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> Enum.reduce(0, &(elem(&1,0) + &2))
      16
  """
  def reduce(_,   {:halt, acc}, _fun),    do: {:halted, acc}
  def reduce(pq,  {:suspend, acc}, fun),  do: {:suspended, acc, &reduce(pq, &1, fun)}
  def reduce(pq,  {:cont, acc}, fun)      do
    cond do
      PriorityQueue.empty?(pq) -> {:done, acc}
      true                     -> {e, pq} = PriorityQueue.pop(pq);
                                  reduce(pq, fun.(e, acc), fun)
    end
  end

  @doc """
  Implements 'member?' for PriorityQueue

  Uses knowledge that we traverse in sorted order

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> Enum.member?({4,nil})
      true
  """
  def member?(pq, e = {k, _v}) do
    if PriorityQueue.empty?(pq) do
      {:ok, false}
    else
      {e_h = {k_h, _}, pq} = PriorityQueue.pop(pq)
      cond do
        k_h > k   -> {:ok, false}
        e === e_h -> {:ok, true}
        true      -> member?(pq, e)
      end
    end
  end

  @doc """
  Implements 'count' for PriorityQueue

      iex> Enum.into([4,{8},3,{1, "first"}], PriorityQueue.new) |> Enum.count
      4
  """
  def count(pq),          do: {:ok, PriorityQueue.size(pq)}
end

