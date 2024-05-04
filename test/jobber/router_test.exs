defmodule Jobber.RouterTest do
  alias Jobber.Router

  use ExUnit.Case
  use Plug.Test

  @opts Router.init([])

  @example_input """
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

  test "returns JSON with ordered tasks" do
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

    conn = conn(:post, "/", @example_input)
    conn = put_req_header(conn, "accept", "application/json")
    conn = put_req_header(conn, "content-type", "application/json")
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert Jason.decode!(conn.resp_body) == expected
  end

  test "returns a shell script" do
    expected = """
    #!/usr/bin/env bash
    touch /tmp/file1
    echo 'Hello World!' > /tmp/file1
    cat /tmp/file1
    rm /tmp/file1
    """

    conn = conn(:post, "/", @example_input)
    conn = put_req_header(conn, "accept", "text/plain")
    conn = put_req_header(conn, "content-type", "application/json")
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert conn.resp_body == expected
  end

  test "bad JSON" do
    body = "not a json"
    conn = conn(:post, "/", body)
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 400
    assert conn.resp_body =~ ~r/{:error,.*Jason/
  end

  test "task cycle" do
    body = """
    {
      "tasks": [
        {
          "name": "task-1",
          "command": "touch /tmp/file1",
          "requires": [
            "task-2"
          ]
        },
        {
          "name": "task-2",
          "command": "cat /tmp/file1",
          "requires": [
            "task-1"
          ]
        }
      ]
    }
    """

    conn = conn(:post, "/", body)
    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 400
    assert conn.resp_body =~ ~r/{:error, :cycle}/
  end
end
