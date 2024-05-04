# Jobber

Jobber is a tiny REST service. It accepts a job as JSON, sorts its tasks
according to their dependencies. It responds either with a JSON or a shell
script in plain text.

## Testing

Run `mix test`.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `jobber` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:jobber, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/jobber>.

