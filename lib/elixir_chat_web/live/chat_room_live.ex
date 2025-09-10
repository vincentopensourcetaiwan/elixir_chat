defmodule ElixirChatWeb.ChatRoomLive do
  use ElixirChatWeb, :live_view

  alias ElixirChat.Chat
  alias ElixirChat.Message

  @impl true
  def mount(%{"room" => room}, _session, socket) do
    if connected?(socket) do
      Chat.subscribe(room)
    end

    changeset = Message.changeset(%Message{}, %{})
    messages = Chat.list_messages(room)

    socket =
      socket
      |> assign(:room, room)
      |> assign(:messages, messages)
      |> assign(:changeset, changeset)
      |> assign(:username, "")
      |> assign(:message_content, "")

    {:ok, socket}
  end

  @impl true
  def handle_event("set_username", params, socket) do
    username = params["username"] || ""
    {:noreply, assign(socket, :username, String.trim(username))}
  end

  @impl true
  def handle_event("send_message", %{"message" => %{"content" => content}}, socket) do
    username = socket.assigns.username
    room = socket.assigns.room

    if String.trim(content) != "" and username != "" do
      case Chat.create_message(%{
        content: String.trim(content),
        username: username,
        room: room
      }) do
        {:ok, message} ->
          Chat.broadcast_message(message, room)
          changeset = Message.changeset(%Message{}, %{})
          {:noreply, assign(socket, changeset: changeset)}

        {:error, changeset} ->
          {:noreply, assign(socket, changeset: changeset)}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    messages = [message | socket.assigns.messages]
    {:noreply, assign(socket, :messages, messages)}
  end
end