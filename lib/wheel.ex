defmodule Math.Wheel do

  @compile :native
  @compile {:hipe, [:o3]}

  @moduledoc """
  Wheel which excludes multiples of 2,3,5,7 from the input.

  Significantly faster to store in a tuple than a Struct
  """
  alias Math.Wheel, as: Wheel


  @cycle2357 [10,2,4,2,4,6,2,6,4,2,4,6,6,2,6,4,2,6,4,6,8,4,2,4,2,4,8,6,4,6,2,4,6,2,6,6,4,2,4,6,2,6,4,2,4,2,10,2]
  @cycle2357_length 210

  @cycle @cycle2357
  @cycle_primes [2,3,5,7]
  @cycle_length @cycle2357_length

  @doc "Create our data structure to store our wheel"
  def new_wheel(candidate \\ 1, multiplier \\ 1), do: {candidate, multiplier, []}

  @doc """
  Returns a stream to generate numbers in sequence

      iex> Math.Wheel.spin_wheel |> Enum.take 5
      [11, 13, 17, 19, 23]
  """
  def spin_wheel do
    Stream.unfold(new_wheel, &spin_wheel/1 )
  end

  @doc """
  Generate next number in sequence (and updated wheel state)

      iex> Math.Wheel.new_wheel |> Math.Wheel.spin_wheel |> elem(0)
      11
  """
  def spin_wheel({i, mult, []}), do: spin_wheel({i, mult, @cycle})
  def spin_wheel({i, 1, [inc | cycle]}), do: {(i+inc), {i+inc, 1, cycle}}
  def spin_wheel({i, mult, [inc | cycle]}), do: {(i+inc)*mult, {i+inc, mult, cycle}}

  @doc """
  Allows the wheel output to be scaled up by a fixed multiplier

      iex> Math.Wheel.new_wheel |> Math.Wheel.update_multiplier(5) |> Math.Wheel.spin_wheel |> elem(0)
      55
  """
  def update_multiplier({i, _mult, cycle}, new_mult), do: {i, new_mult, cycle}

  @doc """
  Accessor for primes used to generate our wheel

      iex> Math.Wheel.initial_primes
      [2, 3, 5, 7]
  """
  def initial_primes, do: @cycle_primes
end


defmodule Math.Wheel.Struct do

  @compile :native
  @compile {:hipe, [:o3]}

  @moduledoc """
  Wheel which excludes multiples of 2,3,5,7 from the input.
  """
  alias Math.Wheel.Struct, as: Wheel

  defstruct candidate: 1, multiplier: 1, cycle: []

  @cycle2357 [10,2,4,2,4,6,2,6,4,2,4,6,6,2,6,4,2,6,4,6,8,4,2,4,2,4,8,6,4,6,2,4,6,2,6,6,4,2,4,6,2,6,4,2,4,2,10,2]
  @cycle2357_length 210

  @cycle @cycle2357
  @cycle_primes [2,3,5,7]
  @cycle_length @cycle2357_length


  def new_wheel(candidate \\ 1, multiplier \\ 1), do: %Wheel{candidate: candidate, multiplier: multiplier}

  def spin_wheel do
    Stream.unfold(%Wheel{multiplier: 1}, &spin_wheel/1 )
  end
  def spin_wheel(wheel = %Wheel{cycle: []}), do: spin_wheel(%{wheel | cycle: @cycle})
  def spin_wheel(wheel = %Wheel{candidate: i, multiplier: 1, cycle: [inc | cycle]}) do
    {i+inc, %{wheel | candidate: (i+inc), cycle: cycle}}
  end
  def spin_wheel(wheel = %Wheel{candidate: i, multiplier: m, cycle: [inc | cycle]}) do
    {(i+inc)*m, %{wheel | candidate: (i+inc), cycle: cycle}}
  end

  def update_multiplier(wheel = %Wheel{}, new_mult) do
    %{wheel | multiplier: new_mult}
  end

end



