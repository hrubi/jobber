defmodule Jobber.DAG do
  @moduledoc """
  Operate on directed acyclic graph.
  """

  defstruct vertices: [],
            edges: []

  @type vertex :: any()

  @typedoc """
  Edge `{from_vertex, to_vertex}`
  """
  @type edge :: {vertex, vertex}

  @type t :: %__MODULE__{
          vertices: [vertex()],
          edges: [edge()]
        }

  @doc """
  Topologically sorts the directed graph.

  Returns `{:ok, order}` where `order` are the topologically sorted vertexes.
  If the graph contains cycles, it returns `{:error, :cycle}`.

  The topological sort is done with Khan's algorithm
  https://www.geeksforgeeks.org/topological-sorting-indegree-based-solution/
  """
  @spec toposort(t) :: {:ok, [vertex()]} | {:error, :cycle}
  def toposort(%__MODULE__{} = graph) do
    graph = uniq_vertices_and_edges(graph)
    in_degrees = in_degrees_map(graph)
    {in_degrees_0, in_degrees} = pop_in_degrees_0(in_degrees)
    queue = :queue.from_list(in_degrees_0)
    toposort(graph, in_degrees, queue, _result = [])
  end

  @spec toposort(t(), in_degrees_map(), :queue.queue(), list()) ::
          {:ok, [vertex()]} | {:error, :cycle}
  defp toposort(graph, in_degrees, queue, result) do
    case :queue.out(queue) do
      {{:value, vertex}, queue} ->
        result = [vertex | result]
        in_degrees = decrease_in_degrees_from(in_degrees, graph, vertex)
        {in_degrees_0, in_degrees} = pop_in_degrees_0(in_degrees)
        queue = enqueue_many(queue, in_degrees_0)
        toposort(graph, in_degrees, queue, result)

      {:empty, _queue} ->
        if map_size(in_degrees) > 0 do
          {:error, :cycle}
        else
          {:ok, Enum.reverse(result)}
        end
    end
  end

  @spec uniq_vertices_and_edges(t()) :: t()
  defp uniq_vertices_and_edges(graph) do
    %__MODULE__{graph | vertices: Enum.uniq(graph.vertices), edges: Enum.uniq(graph.edges)}
  end

  @typep in_degrees_map :: %{vertex() => integer()}

  @spec in_degrees_map(t()) :: in_degrees_map()
  defp in_degrees_map(%__MODULE__{} = graph) do
    initial = Map.new(graph.vertices, &{&1, 0})

    graph.edges
    |> Enum.group_by(&elem(&1, 1), &elem(&1, 0))
    |> Enum.into(initial, fn {to_id, from_ids} ->
      {to_id, Enum.count(from_ids)}
    end)
  end

  @spec pop_in_degrees_0(in_degrees_map) :: {[vertex()], in_degrees_map()}
  defp pop_in_degrees_0(in_degrees) do
    {degree_0, rest} = Map.split_with(in_degrees, fn {_, degree} -> degree == 0 end)
    {Map.keys(degree_0), rest}
  end

  @spec decrease_in_degrees_from(in_degrees_map(), t(), vertex()) :: in_degrees_map()
  defp decrease_in_degrees_from(in_degrees, graph, from_id) do
    vertices = out_vertices(graph, from_id)

    Enum.reduce(vertices, in_degrees, fn vertex, in_degrees ->
      Map.update!(in_degrees, vertex, &(&1 - 1))
    end)
  end

  @spec enqueue_many(:queue.queue(), list()) :: :queue.queue()
  defp enqueue_many(queue, list) do
    Enum.reduce(list, queue, &:queue.in(&1, &2))
  end

  @spec out_vertices(t(), vertex()) :: [vertex()]
  defp out_vertices(%__MODULE__{edges: edges}, from_id) do
    Enum.flat_map(edges, fn
      {^from_id, to_id} -> [to_id]
      {_, _} -> []
    end)
  end
end
