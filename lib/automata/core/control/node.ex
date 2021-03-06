defmodule Automaton.Node do
  @moduledoc """
    This is the primary user control interface to the Automata system. The
    configration parameters are used to inject the appropriate modules into the
    user-defined nodes based on their node_type and other options.

    Notes:
    Initialization and shutdown require extra care:
    on_init: receive extra parameters, fetch data from blackboard/utility,  make requests, etc..
    shutdown: free resources to not effect other actions

    Multi-Agent Systems
      Proactive & Reactive agents
      BDI architecture: Beliefs, Desires, Intentions
  """
  # TODO: Is becoming somewhat of a "Central point of failure". Rather than
  # injecting tons of code into a single process, we should probably link
  # with some GenServer(s) to handle state, restart independently?

  alias Automaton.{Behavior, Composite, Action}

  # When you call use in your module, the __using__ macro is called.
  defmacro __using__(user_opts) do
    quote bind_quoted: [user_opts: user_opts] do
      use DynamicSupervisor
      use Behavior
      # TODO: tie in BlackBoards
      # # global BB
      # use Automata.Blackboard
      # # individual node BB
      # use Automaton.Blackboard
      # TODO: tie in utility system(s) (user configured?) for decisioning
      # global level
      # use Automata.Utility
      # node level
      # use Automaton.Utility

      if Enum.member?(Composite.types(), user_opts[:node_type]) do
        use Composite, user_opts: user_opts
      else
        use Action
      end

      # #######################
      # # GenServer Callbacks #
      # #######################
      def init(arg) do
        IO.inspect(["UserNode", arg], label: __MODULE__)

        {:ok, arg}
      end

      # should tick each subtree at a frequency corresponding to subtrees tick_freq
      # each subtree of the user-defined root node will be ticked recursively
      # every update (at rate tick_freq) as we update the tree until we find
      # the leaf node that is currently running (will be an action).
      def tick(status \\ :bh_fresh, arg \\ "stuff") do
        if status != :running, do: on_init(arg)
        status = update()
        if status != :running, do: on_terminate(status)
        {:ok, status}
      end

      def child_spec do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, []},
          restart: :temporary,
          shutdown: 5000,
          type: :worker
        }
      end

      #####################
      # Private Functions #
      #####################

      #####################
      # typespec          #
      #####################
      # @type a_node :: {
      #         term() | :undefined,
      #         child() | :restarting,
      #         :worker | :supervisor,
      #         :supervisor.modules()
      #       }
      # Defoverridable makes the given functions in the current module overridable
      defoverridable on_init: 1, update: 0, on_terminate: 1, tick: 2
    end
  end
end
