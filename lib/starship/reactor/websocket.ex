defmodule Starship.Reactor.Websocket do
  @moduledoc """
  Functions for handling Websocket Requests in `Starship.Reactor`.
  """

  alias Starship.Reactor
  alias Starship.Reactor.Conn
  alias Starship.Reactor.Websocket
  alias Starship.Reactor.Websocket.Frame

  import Starship.Reactor.Websocket.Handshake,
    only: [successful_handshake: 3, rejected_handshake: 1]

  require Logger

  @spec handle_ws_frame(binary, map) :: {Reactor.connection_state(), map}
  def handle_ws_frame(frame, config) do
    fragmentation_opcode = Map.get(config, :ws_fragment_opcode)

    case Websocket.Frame.parse_frame(frame, fragmentation_opcode) do
      {:ok, :fin, :masked, :text, payload} -> handle_text(payload, config)
      # {:ok, :fin, :masked, :binary, payload} -> handle_binary(payload, config)
      {:ok, :fin, :masked, :close, payload} -> handle_close(payload, config)
      {:ok, :fin, :masked, :ping, payload} -> handle_ping(payload, config)
      {:ok, :fin, :masked, :pong, nil} -> handle_pong(config)
      {:ok, :not_fin, :masked, opcode, buffer} -> handle_fragment(buffer, config, opcode)
      # {:ok, :not_fin, :masked, :binary, payload} -> handle_fragment(payload, config)
      {:error, reason} -> handle_error(reason, config)
    end
  end

  @spec handle_ws_handshake(Conn.t(), map) :: {Reactor.connection_state(), map}
  def handle_ws_handshake(%Conn{} = conn, config) do
    {_, host} = List.keyfind(conn.headers, "host", 0)
    {ws_handler, opts} = Reactor.get_host_handler(:ws, host, conn.path, config.hosts)
    config = Map.put(config, :handler, ws_handler)

    case ws_handler.connect(conn, config) do
      :reject -> {:close, rejected_handshake(config)}
      {:ok, config} -> {:keepalive, successful_handshake(conn, config, opts)}
    end
  end

  @spec handle_ping(bitstring, map) :: {:keepalive, map}
  def handle_ping(payload, config) do
    response = Frame.generate_frame(payload, :pong)
    config.transport.send(config.socket, response)
    {:keepalive, config}
  end

  @spec handle_pong(map) :: {:keepalive, map}
  def handle_pong(config) do
    {:keepalive, config}
  end

  @spec handle_text(bitstring, map) :: {:keepalive, map}
  def handle_text(payload, config) do
    {response, config} = config.handler.handle_text(payload, config)
    response = Frame.generate_frame(response, :text)
    config.transport.send(config.socket, response)
    {:keepalive, config}
  end

  @spec handle_binary(binary, map) :: {:keepalive, map}
  def handle_binary(payload, config) do
    {response, config} = config.handler.handle_binary(payload, config)
    response = Frame.generate_frame(response, :text)
    config.transport.send(config.socket, response)
    {:keepalive, config}
  end

  @spec handle_close(bitstring, map) :: {:close, map}
  def handle_close(payload, config) do
    {response, config} = config.handler.handle_close(payload, config)
    response = Frame.generate_frame(response, :close)
    config.transport.send(config.socket, response)
    {:close, config}
  end

  @spec handle_fragment(bitstring, map, Websocket.Frame.opcode()) :: {:keepalive, map}
  def handle_fragment(buffer, config, fragment_opcode) do
    config = Map.put(config, :ws_fragment_opcode, fragment_opcode)
    buf = Map.get(config, :buf, <<>>)
    {:keepalive, Map.put(config, :buf, buf <> buffer)}
  end

  @spec handle_error(atom, map) :: {:close, map}
  def handle_error(error, config) do
    Logger.error(["Websocket Frame Error: ", inspect(error)])
    {:close, config}
  end
end
