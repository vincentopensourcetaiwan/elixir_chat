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
          # Broadcast to all subscribers (including this one)
          Chat.broadcast_message(message, room)
          
          # Clear the form immediately for better UX
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
    # Check if message is for this room and not already in the list
    if message.room == socket.assigns.room do
      # Check if message already exists to prevent duplicates
      existing_ids = Enum.map(socket.assigns.messages, & &1.id)
      
      if message.id not in existing_ids do
        # Add new message to the end of the list (newest at bottom for display)
        messages = socket.assigns.messages ++ [message]
        
        # Trigger a client-side event for auto-scroll
        socket = push_event(socket, "new_message", %{})
        
        {:noreply, assign(socket, :messages, messages)}
      else
        {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end
end