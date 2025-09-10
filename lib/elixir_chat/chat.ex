defmodule ElixirChat.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias ElixirChat.Repo
  alias ElixirChat.Message

  @doc """
  Returns the list of messages for a specific room.
  """
  def list_messages(room) do
    Message
    |> where([m], m.room == ^room)
    |> order_by([m], desc: m.inserted_at)
    |> limit(50)
    |> Repo.all()
    |> Enum.reverse()
  end

  @doc """
  Creates a message.
  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Subscribes to real-time updates for a specific room.
  """
  def subscribe(room) do
    Phoenix.PubSub.subscribe(ElixirChat.PubSub, "room:#{room}")
  end

  @doc """
  Broadcasts a message to all subscribers of a room.
  """
  def broadcast_message(message, room) do
    Phoenix.PubSub.broadcast(ElixirChat.PubSub, "room:#{room}", {:new_message, message})
  end
end