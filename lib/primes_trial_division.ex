defmodule Math.Primes.TrialDivision do

    @moduledoc """
    Generate a list of prime numbers

    Basic algorithm is trial division.
    Main performance challenge is keeping a list of found primes in ascending
    order. Performance is higher if we test in ascending order.
    However, it's faster to append to the head of a list... Reverse is also slow

    So the main performance variation here observes that we only need a list of
    primes up to sqrt(candidate), and this grows slowly. So we keep an acc of
    all primes found, and a separate list to test against. If the test list is
    too short, then reverse the list of all primes and substitute that.

    We use a "wheel", ie we exclude numbers that are multiples of 2,3,5,7 from
    the input candidate numbers to test. The speedup is great on small ranges,
    but asymtotically zero as the range gets larger

    These tight inner loops also show up that handwritten list tests are
    significantly faster than their Enum variants. But of course there is less
    code, so of course. Compare the two test_prime variations to see this

    There is also a stream implementation which will produce endless incremental
    primes
    """


    @doc """
    Compute all primes up to and including "up_to" using trial division

        iex> Math.Primes.TrialDivision.primes_up_to_slow(11)
        [2, 3, 5, 7, 11]
    """
    def primes_up_to_slow(up_to) do
        wheel2357
        |> Stream.take_while( &( &1 <= up_to ) )
        |> Enum.reduce(
            [],
            fn(x, primes) ->
                limit=Float.ceil(:math.sqrt(x))
                if(test_prime_fast?(x, limit, Enum.reverse(primes))) do
                    [x|primes]
                else
                    primes
                end
            end
        )
        |> Enum.concat([7,5,3,2])
        |> Enum.reverse
    end

    @doc """
    Compute all primes up to and including "up_to" using trial division

        iex> Math.Primes.TrialDivision.primes_up_to_fast(11)
        [2, 3, 5, 7, 11]
    """
    def primes_up_to_fast(up_to) do
        wheel2357
        |> Stream.take_while( &( &1 <= up_to ) )
        |> Enum.reduce(
            {[], {121, [11]}},
            fn(x, {primes, ptt = { test_valid_to, primes_to_test} }) ->
                {test_valid_to, primes_to_test} = update_primes_to_test(x, ptt, primes)

                if(test_prime?(x, primes_to_test)) do
                    {[x|primes], {test_valid_to, primes_to_test}}
                else
                    {primes, {test_valid_to, primes_to_test}}
                end
            end
        )
        |> elem(0)
        |> Enum.concat([7,5,3,2])
        |> Enum.reverse
    end

    @doc """
    Generate a stream of primes

        iex(2)> Math.Primes.TrialDivision.primes_stream |> Enum.take 5
        [2, 3, 5, 7, 11]
    """
    def primes_stream do
        primes =
        wheel2357
        |> Stream.transform(
            {[], {121, [11]}},
            fn(x, {primes, ptt = { test_valid_to, primes_to_test} }) ->
                {test_valid_to, primes_to_test} = update_primes_to_test(x, ptt, primes)

                if(test_prime?(x, primes_to_test)) do
                    {[x], {[x|primes], {test_valid_to, primes_to_test}}}
                else
                    {[], {primes, {test_valid_to, primes_to_test}}}
                end
            end
            )

        Stream.concat([2,3,5,7], primes)
    end

    @doc "Test if relatively prime to a list of candidate primes"
    defp test_prime?(n, primes) do
        test_up_to=Float.ceil(:math.sqrt(n))
        test_prime_fast?(n, test_up_to, primes)
    end

    defp test_prime_fast?(_n, _ubound, []), do: true
    defp test_prime_fast?(_n, ubound, [p|_]) when p > ubound, do: true

    defp test_prime_fast?(n, _ubound, [p|_]) when rem(n,p) == 0, do: false
    defp test_prime_fast?(n, ubound, [p|primes]) when rem(n,p) != 0 do
        test_prime_fast?(n, ubound, primes)
    end

    @doc "This version is about 2-3x slower. Why?"
    defp test_prime_slow?(n, ubound, primes) do
        primes
        |> Stream.take_while( &( &1 <= ubound ) )
        |> Enum.all?( &( rem(n, &1) != 0 ) )
    end

    defp update_primes_to_test(x, {test_valid_to, primes_to_test}, primes) do
        if(x > test_valid_to) do
            test_valid_to = List.first(primes)
            test_valid_to = test_valid_to * test_valid_to
            primes_to_test = Enum.reverse(primes)
        end
        {test_valid_to, primes_to_test}
    end


    @doc "Wheel which excludes multiples of 2,3,5,7 from the input. Barely faster then 'odd_numbers'..?"
    def wheel2357 do
        Stream.cycle([2,4,2,4,6,2,6,4,2,4,6,6,2,6,4,2,6,4,6,8,4,2,4,2,4,8,6,4,6,2,4,6,2,6,6,4,2,4,6,2,6,4,2,4,2,10,2,10])
                |> Stream.transform( 11, fn(i, acc) -> {[acc], i+acc} end )
    end

    def odd_numbers do
        Stream.iterate(3, &(&1+2) )
    end


end