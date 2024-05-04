defmodule Jobber.JobTest do
  use ExUnit.Case
  alias Jobber.Job

  @input """
  {
    "tasks": [
      {
        "name": "task-1",
        "command": "touch /tmp/file1"
      },
      {
        "name": "task-2",
        "command": "cat /tmp/file1",
        "requires": [
          "task-3"
        ]
      },
      {
        "name": "task-3",
        "command": "echo 'Hello World!' > /tmp/file1",
        "requires": [
          "task-1"
        ]
      },
      {
        "name": "task-4",
        "command": "rm /tmp/file1",
        "requires": [
          "task-2",
          "task-3"
        ]
      }
    ]
  }
  """

  test "example use case - map output" do
    expected = %{
      "tasks" => [
        %{
          "name" => "task-1",
          "command" => "touch /tmp/file1"
        },
        %{
          "name" => "task-3",
          "command" => "echo 'Hello World!' > /tmp/file1"
        },
        %{
          "name" => "task-2",
          "command" => "cat /tmp/file1"
        },
        %{
          "name" => "task-4",
          "command" => "rm /tmp/file1"
        }
      ]
    }

    assert {:ok, result} = @input |> Jason.decode!() |> Job.sort()
    assert expected == result
  end

  test "example use case - shell output" do
    expected = """
    #!/usr/bin/env bash
    touch /tmp/file1
    echo 'Hello World!' > /tmp/file1
    cat /tmp/file1
    rm /tmp/file1
    """

    assert {:ok, job} = @input |> Jason.decode!() |> Job.sort()
    assert expected == Job.to_shell(job)
  end
end
