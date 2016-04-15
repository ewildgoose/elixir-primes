

##############################################################################


defmodule Math.Primes do

  @compile :native
  @compile {:hipe, [:o3]}

  @moduledoc """
  Sieve Prime Numbers using a Priority Queue of iterators

  Based on the algorithm by O'Neill - http://www.cs.hmc.edu/~oneill/papers/Sieve-JFP.pdf

  The algorithm is to keep a table of composites in numerical order and
  increment them from smallest to largest. Gaps indicate a prime is found
  (so we add it to the composites table), eg
  2 -> 4, 6, 8, 10
  3 -> 9, 12, 15, 18
  5 -> 25, 30, 35, 40
  7 -> 49, 56, 63, 70

  An appropriate datatype is a priority queue. We use a pairing heap here
  """

#  import Math.Wheel
  alias Math.Wheel

  defstruct primes: nil, prime_q: nil, candidate: 9, wheel_primes: [2,3,5,7], wheel: nil


  ################################
  #

  @doc """
  Insert our next composite into our table
  We copy the wheel state and use this to generate subsequent composites
  (scaled up by the prime, ie we are generating: wheel x prime)
  """
  defp insert_prime(pq, p, wheel) do
    wheel = Wheel.update_multiplier(wheel, p)
    PriorityQueue.put(pq, p*p, wheel)
  end

  @doc """
  Update our table of composites such that min composite becomes >= n
  """
  defp adjust_table(pq, n) do
    case PriorityQueue.min(pq) do
      {min, v} when (min < n) -> pq
                                 |> PriorityQueue.delete_min
                                 |> PriorityQueue.put( Wheel.spin_wheel(v) )
                                 |> adjust_table(n)
      {_min, _v} -> pq
      # :error   -> pq
    end
  end

  ################################
  #


  @doc """
  Produce an endless stream of primes

  ## Examples

      iex> Math.Primes.sieve |> Enum.take(5)
      [2, 3, 5, 7, 11]
  """
  def sieve do
    pq = PriorityQueue.new
    wheel = Wheel.new_wheel

    # first candidate must be prime, initialises our data structures
    {x, wheel} = Wheel.spin_wheel(wheel);
    pq = insert_prime(pq, x, wheel)

    Stream.concat(Wheel.initial_primes ++ [x],
                  Stream.unfold({pq, wheel}, fn {pq, wheel} -> sieve_next(pq, wheel) end) )
  end

  @doc """
  Produce a list of all primes up to (including) "up_to"
  FIXME: Can produce primes greater then requested
  if "up_to" is less than first element of the wheel

  ## Examples

      iex> Math.Primes.sieve(11)
      [2, 3, 5, 7, 11]
  """
  def sieve(up_to) do
    pq = PriorityQueue.new
    wheel = Wheel.new_wheel

    # first candidate must be prime, initialises our data structures
    {x, wheel} = Wheel.spin_wheel(wheel);
    pq = insert_prime(pq, x, wheel)

    # OK, lets get sieving
    sieve(up_to, pq, wheel, [x | Enum.reverse(Wheel.initial_primes)] )
  end


  defp sieve(up_to, pq, wheel, acc) do
    {p, {pq, wheel}} = sieve_next(pq, wheel)
    cond do
      p <= up_to -> sieve(up_to, pq, wheel, [p|acc])
      true      -> Enum.reverse(acc)
    end
  end

  @doc """
  Returns the next incremental prime
  pq is our current sieve state
  wheel is the generator of integers to test for primality
  """
  defp sieve_next(pq, wheel) do
    {x, wheel} = Wheel.spin_wheel(wheel);
    pq = adjust_table(pq, x)
    case PriorityQueue.min(pq) do
      {min, _v} when (min == x) -> sieve_next(pq, wheel)
      {_min, _v}                 -> {x, {insert_prime(pq, x, wheel), wheel}}
      # :error                    -> {x, {insert_prime(pq, x, wheel), wheel}}
    end
  end

end
