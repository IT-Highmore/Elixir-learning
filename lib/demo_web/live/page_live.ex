defmodule DemoWeb.PageLive do
  use DemoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, location: "Shanghai", weather: weather("Shanghai"), val: 0, query: "", results: %{})}
  end

  @impl true
  def handle_event("suggest", %{"q" => query}, socket) do
    {:noreply, assign(socket, results: search(query), query: query)}
  end

  @impl true
  def handle_event("search", %{"q" => query}, socket) do
    case search(query) do
      %{^query => vsn} ->
        {:noreply, redirect(socket, external: "https://hexdocs.pm/#{query}/#{vsn}")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "No dependencies found matching \"#{query}\"")
         |> assign(results: %{}, query: query)}
    end
  end

  defp search(query) do
    if not DemoWeb.Endpoint.config(:code_reloader) do
      raise "action disabled when not in development"
    end

    for {app, desc, vsn} <- Application.started_applications(),
        app = to_string(app),
        String.starts_with?(app, query) and not List.starts_with?(desc, ~c"ERTS"),
        into: %{},
        do: {app, vsn}
  end

  def handle_event("set-location", %{"location" => location}, socket) do
    {:noreply, put_location(socket, location)}
  end

  defp put_location(socket, location) do
    assign(socket, location: location, weather: weather(location))
  end

  defp weather(local) do
    {:ok, {{_, 200, _}, _, body}} =
     :httpc.request(:get, {"http://wttr.in/#{URI.encode(local)}?format=1", []}, [], [])

    IO.iodata_to_binary(body)
  end


  def handle_event("inc", _value, socket) do
    {:noreply, update(socket, :val, &(&1 + 1))}
  end

  def handle_event("dec", _value, socket) do
    {:noreply, update(socket, :val, &(&1 - 1))}
  end
end
