Mix.install([
  {:bumblebee, github: "elixir-nx/bumblebee", ref: "23de64b1b88ed3aad266025c207f255312b80ba6"},
  {:nx, "~> 0.5.3"},
  {:exla, "~> 0.5.3"},
  {:axon, "~> 0.5.1"},
  {:bandit, "~> 1.0.0-pre.6"},
  {:plug, "~> 1.14.2"}
])

Nx.global_default_backend(EXLA.Backend)

model_name = "sentence-transformers/all-MiniLM-L6-v2"
{:ok, model_info} = Bumblebee.load_model({:hf, model_name})
{:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_name})
serving = Bumblebee.Text.TextEmbedding.text_embedding(model_info, tokenizer)

modules = for i <- 1..System.schedulers_online() do
  Module.concat(MyServing, to_string(i))
end

defmodule MyPlug do
  def init(_), do: []

  def call(conn, _opts) do
    Nx.Serving.batched_run(Enum.random(unquote(modules)), ["this is a test"])
    Plug.Conn.send_resp(conn, 200, "ok")
  end
end

servings = for mod <- modules do
  Supervisor.child_spec({Nx.Serving, serving: serving, name: mod}, id: mod)
end

{:ok, _pid} = Supervisor.start_link(
  [
    servings,
    {Bandit, plug: MyPlug, port: System.get_env("PORT", "5001") |> String.to_integer()}
  ]
  |> List.flatten(),
  strategy: :one_for_one
)

Process.sleep(:infinity)
