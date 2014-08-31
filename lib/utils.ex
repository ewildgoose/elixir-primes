defmodule Utils do
    @moduledoc """
    Useful functions for solving problems
    """

    @doc """
    Benchmarks a block and prints the timings
    Beware, seems to eat the normal output of a function
    """
    defmacro benchmark([do: content]) do
        quote do
            s = :erlang.now
            unquote(content)
            e = :erlang.now
            IO.inspect :timer.now_diff(e, s) / (1000 * 1000)
        end
    end

    @doc """
    Time running a function, but print the output
    Similar to :timer.tc
    """
    def time(func) do
        benchmark do
            IO.inspect func
        end
    end


    ##
    ## Stream Related Functions
    ##





    ##
    ## Enum Related Functions
    ##






end