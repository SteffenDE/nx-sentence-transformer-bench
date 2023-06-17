Mix.install([
  {:bumblebee, "~> 0.3.0"},
  {:nx, "~> 0.5.3"},
  {:exla, "~> 0.5.3"},
  {:axon, "~> 0.5.1"},
  {:bandit, "~> 1.0.0-pre.9"},
  {:plug, "~> 1.14.2"}
])

Nx.global_default_backend(EXLA.Backend)

model_name = "sentence-transformers/all-MiniLM-L6-v2"
{:ok, model_info} = Bumblebee.load_model({:hf, model_name})
{:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, model_name})

:persistent_term.put(:model_info, model_info)
:persistent_term.put(:tokenizer, tokenizer)

defmodule Predictor do
  def predict(model_info, tokenizer) do
    inputs = Bumblebee.apply_tokenizer(tokenizer, ["this is a test"])
    _embedding = Axon.predict(model_info.model, model_info.params, inputs, compiler: EXLA)
  end
end

defmodule MyPlug do
  def init(_), do: []

  def call(conn, _opts) do
    model_info = :persistent_term.get(:model_info)
    tokenizer = :persistent_term.get(:tokenizer)
    Predictor.predict(model_info, tokenizer)

    Plug.Conn.send_resp(conn, 200, "ok")
  end
end

{:ok, _pid} = Supervisor.start_link([
  {Bandit, plug: MyPlug, port: System.get_env("PORT", "5001") |> String.to_integer()}
], strategy: :one_for_one)

Process.sleep(:infinity)
