defmodule LiveBeats.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    LiveBeats.MediaLibrary.attach()
    topologies = Application.get_env(:libcluster, :topologies) || []

    children =
      process_specs([
        {Cluster.Supervisor, [topologies, [name: LiveBeats.ClusterSupervisor]]},
        {Task.Supervisor, name: LiveBeats.TaskSupervisor},
        LiveBeats.EdgeDB,
        # Start the Telemetry supervisor
        LiveBeatsWeb.Telemetry,
        # Start the PubSub system
        {Phoenix.PubSub, name: LiveBeats.PubSub},
        # start presence
        LiveBeatsWeb.Presence,
        # Start the Endpoint (http/https)
        LiveBeatsWeb.Endpoint,
        spec_if(LiveBeats.config([:songs_cleaner, :use]), songs_cleaner_spec())

        # Start a worker by calling: LiveBeats.Worker.start_link(arg)
        # {LiveBeats.Worker, arg}
      ])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveBeats.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl Application
  def config_change(changed, _new, removed) do
    LiveBeatsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp spec_if(condition, spec) do
    if condition do
      spec
    else
      nil
    end
  end

  defp process_specs(specs) do
    Enum.reject(specs, &is_nil/1)
  end

  defp songs_cleaner_spec do
    # Expire songs every six hours
    {LiveBeats.SongsCleaner, interval: LiveBeats.config([:songs_cleaner, :interval])}
  end
end
