Mix.install([
  {:bumblebee, github: "elixir-nx/bumblebee", ref: "23de64b1b88ed3aad266025c207f255312b80ba6"},
  {:nx, "~> 0.5.3"},
  {:exla, "~> 0.5.3"},
  {:axon, "~> 0.5.1"},
  {:bandit, "~> 1.0.0-pre.6"},
  {:plug, "~> 1.14.2"}
])

Nx.global_default_backend(EXLA.Backend)
Nx.Defn.global_default_options(compiler: EXLA, client: :host)

model_name = "sentence-transformers/all-MiniLM-L6-v2"
{:ok, model_info} = Bumblebee.load_model({:hf, model_name})
{:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_name})

serving =
  Bumblebee.Text.TextEmbedding.text_embedding(model_info, tokenizer,
    compile: [batch_size: 32, sequence_length: 128],
    defn_options: [compiler: EXLA]
  )

so_reuseport =
  case :os.type() do
    {:unix, :linux} -> {:raw, 1, 15, <<1::32-native>>}
    {:unix, :darwin} -> {:raw, 0xffff, 0x0200, <<1::32-native>>}
  end

defmodule MyPlug do
  def init(_), do: []

  def call(conn, _opts) do
    Nx.Serving.batched_run(MyServing, ["this is a test"])
    Plug.Conn.send_resp(conn, 200, "ok")
  end
end

{:ok, _pid} =
  Supervisor.start_link(
    [
      {Nx.Serving, serving: serving, name: MyServing, partitions: true},
      {Bandit, plug: MyPlug, port: System.get_env("PORT", "5001") |> String.to_integer()}
    ],
    strategy: :one_for_one
  )

Process.sleep(:infinity)
