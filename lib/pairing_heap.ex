defmodule PairingHeap do

  @compile :native
  @compile {:hipe, [:o3]}

  @moduledoc """
  Pairing Heap implementation
  see:
      http://en.wikipedia.org/wiki/Pairing_heap

  Guts: pairing heaps
  A pairing heap is either nil or a term {key, value, [sub_heaps]}
  where sub_heaps is a list of heaps.
  """

  @type key :: any
  @type value :: any

  @type t :: {key, value, list} | nil
  @type element :: {key, value}

  @doc """
  return the heap with the min item removed
  """
  @spec delete_min(t) :: t
  def delete_min( {_key, _v, sub_heaps} ) do
    pair(sub_heaps)
  end

  @doc """
  Merge (meld) two heaps
  """
  @spec meld(t, t) :: t
  def meld(nil, heap), do: heap
  def meld(heap, nil), do: heap
  # defp meld(_l = {key_l, value_l, sub_l}, r = {key_r, _value_r, _sub_r}) when key_l < key_r do
  #   {key_l, value_l, [r | sub_l]}
  # end
  # defp meld(l, _r = {key_r, value_r, sub_r}) do
  #   {key_r, value_r, [l | sub_r]}
  # end
  def meld(l = {key_l, value_l, sub_l}, r = {key_r, value_r, sub_r}) do
    cond do
      key_l < key_r -> {key_l, value_l, [r | sub_l]}
      true          -> {key_r, value_r, [l | sub_r]}
    end
  end

  @doc """
  Merge (meld) two heaps
  """
  @spec merge(t, t) :: t
  def merge(h1, h2), do: meld(h1, h2)

  @doc """
  min item in the heap
  """
  @spec min(t) :: element | :error
  def min( nil ), do: :error
  def min( {key, value, _} ), do: {key, value}

  @doc """
  Create new empty heap.
  Optionally pass in initial key, value
  """
  @spec new :: t
  @spec new(key, value) :: t
  def new(), do: nil
  def new(key, value), do: {key, value, []}

  @doc """
  Pairing Heaps get their name from the special "pair" operation, which is used to
  'Pair up' (recursively meld) a list of pairing heaps.
  """
  @spec pair([t]) :: t
  defp pair([]), do: nil
  defp pair([h]), do: h
  defp pair([h0, h1 | hs]), do: meld(meld(h0, h1), pair(hs))

  @doc """
  Returns the min item, as well as the queue without the min item
  Equivalent to:
    {min(heap), delete_min(heap)}
  """
  @spec pop(t) :: {element, t}
  def pop(heap) do
    {min(heap), delete_min(heap)}
  end


  @doc """
  Add element X to priority queue
  """
  @spec put(t, key, value) :: t
  def put(heap, key, value) do
    meld(heap, new(key, value))
  end

end
