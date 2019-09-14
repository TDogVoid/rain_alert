defmodule RainAlert do
  use GenServer
  @moduledoc """
  Documentation for RainAlert.
  """

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(state) do
    schedule_work()
    {:ok, state}
  end

  defp schedule_work() do
    IO.inspect("scheduling check weather")
    Process.send_after(self(), :check, 30 * 60 * 1000) # Every 30 mins
  end

  def handle_info(:check, state) do
    check()
    schedule_work()
    {:noreply, state}
  end


  def check() do
    IO.inspect("checking weather")
    data = get_weather()
    if is_going_to_rain_or_raining(data) do
      send_alert(data["minutely"]["summary"])
    end
    IO.inspect(data["minutely"]["summary"])
  end

  defp send_alert(message) do
    url = "https://api.pushover.net/1/messages.json"
    token = Application.fetch_env!(:rain_alert, :pushover_api)
    user = Application.fetch_env!(:rain_alert, :pushover_user)

    HTTPoison.post(url, [], [], params: %{token: token, user: user, message: message})
  end

  defp get_weather do
    key = Application.fetch_env!(:rain_alert, :key)
    lat = Application.fetch_env!(:rain_alert, :lat)
    long = Application.fetch_env!(:rain_alert, :long)

    HTTPoison.get!("https://api.darksky.net/forecast/#{key}/#{lat},#{long}").body
    |> Jason.decode!()
  end

  defp is_going_to_rain_or_raining(data) do
    data["minutely"]["icon"] == "rain"
  end
end
