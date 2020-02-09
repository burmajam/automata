defmodule Automata.Composite.Sequence do
  @moduledoc """
    Supervises user-defined sequence actions. When the execution of a sequence
    node starts, then the node’s children are executed in succession from left
    to right, returning to its parent a status failure (or running) as soon as a
    child that returns failure (or running) is found. It returns success only
    when all the children return success. The purpose of the sequence node is to
    carry out the tasks that are deﬁned by a strict sequence of sub-tasks, in
    which all have to succeed.

    A Sequence will return immediately with a failure status code when one of
    its children fails. As long as its children are succeeding, it will keep
    going. If it runs out of children, it will return in success.

    class Sequence (Task):
      def run():
        for c in children:
          if not c.run():
            return False
        return True

    class Sequence : Composite
      virtual void onInitialize()
      {
          m_CurrentChild = m_Children.begin();
      }

      virtual Status update()
      {
          // Keep going until a child behavior says it's running.
          for (;;)
          {
              Status s = (*m_CurrentChild)->tick();

              // If the child fails, or keeps running, do the same.
              if (s != BH_SUCCESS)
              {
                  return s;
              }

              // Hit the end of the array, job done!
              if (++m_CurrentChild == m_Children.end())
              {
                  return BH_SUCCESS;
              }
          }
      }

  """
  use Supervisor

  @name :sequence

  ## Client API
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts ++ [name: @name])
  end

  def stop do
    GenServer.cast(@name, :stop)
  end

  ## Callbacks
  def init(:ok) do
    IO.inspect(@name, label: __MODULE__)

    {:ok, %{}}
  end

  ## Helper Functions
end
