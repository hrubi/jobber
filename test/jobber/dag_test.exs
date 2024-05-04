defmodule Jobber.DAGTest do
  use ExUnit.Case
  alias Jobber.DAG

  test "toposort - example" do
    input = %DAG{
      vertices: ["task-1", "task-2", "task-3", "task-4"],
      edges: [
        {"task-1", "task-3"},
        {"task-2", "task-4"},
        {"task-3", "task-2"},
        {"task-3", "task-4"}
      ]
    }

    expected = [
      "task-1",
      "task-3",
      "task-2",
      "task-4"
    ]

    assert {:ok, expected} == DAG.toposort(input)
  end

  test "toposort - disconnected" do
    input = %DAG{
      vertices: ["task-1", "task-2", "task-3", "task-4"],
      edges: [
        {"task-1", "task-4"},
        {"task-2", "task-3"}
      ]
    }

    assert {:ok, sorted} = DAG.toposort(input)
    assert before?(sorted, "task-1", "task-4")
    assert before?(sorted, "task-2", "task-3")
  end

  test "toposort - cycle" do
    input = %DAG{
      vertices: ["task-1", "task-2", "task-3", "task-4"],
      edges: [
        {"task-1", "task-2"},
        {"task-2", "task-1"},
        {"task-3", "task-4"}
      ]
    }

    assert {:error, :cycle} = DAG.toposort(input)
  end

  test "toposort - loop" do
    input = %DAG{
      vertices: ["task-1", "task-2", "task-3", "task-4"],
      edges: [
        {"task-1", "task-1"},
        {"task-2", "task-3"},
        {"task-3", "task-4"}
      ]
    }

    assert {:error, :cycle} = DAG.toposort(input)
  end

  test "toposort - empty" do
    assert {:ok, []} = DAG.toposort(%DAG{vertices: [], edges: []})
  end

  test "toposort - duplicate edges" do
    input = %DAG{
      vertices: ["task-1", "task-2", "task-3", "task-4"],
      edges: [
        {"task-1", "task-3"},
        {"task-1", "task-3"},
        {"task-2", "task-4"},
        {"task-3", "task-2"},
        {"task-3", "task-2"},
        {"task-3", "task-4"}
      ]
    }

    expected = [
      "task-1",
      "task-3",
      "task-2",
      "task-4"
    ]

    assert {:ok, expected} == DAG.toposort(input)
  end

  defp before?(list, a, b) do
    Enum.find_index(list, &(&1 == a)) < Enum.find_index(list, &(&1 == b))
  end
end
