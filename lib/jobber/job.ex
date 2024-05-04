defmodule Jobber.Job do
  @moduledoc """
  Manipulates Job with tasks.
  """

  alias Jobber.DAG

  @typedoc """
  Job in format:
  ```
  %{
    "tasks" => [
      %{
        "name" => "task-1",
        "command" => "touch /tmp/file1"
      },
      %{
        "name" => "task-2",
        "command" => "cat /tmp/file1",
        "requires" => ["task-1"]
      },
      ...
    ]
  }
  """
  @type t :: %{
          String.t() => [task()]
        }

  @typedoc """
  Task in format:
  ```
  %{
    "name" => "task-2",
    "command" => "cat /tmp/file1",
    "requires" => ["task-1"]
  }
  ```

  The `"requires"` is optional.
  """
  @type task :: %{
          String.t() => any()
        }

  @doc """
  Sorts the job tasks.

  It removes the `"requires"` field from the resulting tasks.

  Returns `{:error, :cycle}` if the jobs can not be sorted.
  """
  @spec sort(t()) :: {:ok, t()} | {:error, :cycle}
  def sort(job) do
    if tasks = Map.get(job, "tasks") do
      tasks = task_map(tasks)
      graph = tasks_to_dag(tasks)

      with {:ok, sorted} <- DAG.toposort(graph) do
        tasks = sorted_to_tasks(sorted, tasks)
        {:ok, %{"tasks" => tasks}}
      end
    else
      job
    end
  end

  @doc """
  Returns a shell script for the job.

  The `"command"` fields of individual tasks are assembled to a shell script in
  the order they appear in the job.
  """
  @spec to_shell(t()) :: String.t()
  def to_shell(job) do
    start = "#!/usr/bin/env bash"
    tasks = Map.get(job, "tasks", [])

    commands =
      Enum.flat_map(tasks, fn
        %{"command" => command} -> [command]
        _ -> []
      end)

    Enum.join([start | commands], "\n") <> "\n"
  end

  @typep task_name :: String.t()

  @spec task_map([task()]) :: %{task_name() => task()}
  defp task_map(tasks) do
    tasks
    |> Enum.filter(&match?(%{"name" => _}, &1))
    |> Map.new(fn %{"name" => name} = task -> {name, task} end)
  end

  @spec tasks_to_dag(%{task_name() => task()}) :: DAG.t()
  defp tasks_to_dag(tasks) do
    vertices = Map.keys(tasks)

    edges =
      Enum.flat_map(tasks, fn {name, task} ->
        requires = Map.get(task, "requires", [])
        Enum.map(requires, &{&1, name})
      end)

    %DAG{
      vertices: vertices,
      edges: edges
    }
  end

  @spec sorted_to_tasks([task_name()], %{task_name() => task()}) :: [task()]
  defp sorted_to_tasks(sorted, tasks) do
    Enum.map(sorted, fn name ->
      tasks
      |> Map.fetch!(name)
      |> Map.delete("requires")
    end)
  end
end
