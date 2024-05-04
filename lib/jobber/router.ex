defmodule Jobber.Router do
  alias Jobber.Job
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  # Receives the "job" definition in the body.
  # Sorts the job tasks according to their dependencies.
  #
  # Output depends on the "Accept" header:
  # * "application/json" - JSON output
  # * anything else      - output a plain text with shell script
  post "/" do
    with {:ok, body, conn} <- read_body(conn),
         {:ok, decoded} <- Jason.decode(body),
         {:ok, result} <- Job.sort(decoded) do
      accept = accept_types(conn)

      resp =
        if "application/json" in accept do
          Jason.encode!(result)
        else
          Job.to_shell(result)
        end

      send_resp(conn, 200, resp)
    else
      {:error, _} = error ->
        send_resp(conn, 400, inspect(error))
    end
  end

  match _ do
    send_resp(conn, 404, "Not found!")
  end

  defp accept_types(conn) do
    conn
    |> get_req_header("accept")
    |> List.first("")
    |> String.replace(~r/;[^,]*/, "", global: true)
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.uniq()
  end
end
