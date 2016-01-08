defmodule Integration.SlackTest do
  use Cog.AdapterCase, adapter: Cog.Adapters.Slack

  @moduletag :slack

  setup do
    user = user("botci")
    |> with_chat_handle_for("Slack")

    {:ok, %{user: user}}
  end

  test "running the st-echo command", %{user: user} do
    user |> with_permission("operable:st-echo")

    message = send_message user, "@deckard: operable:st-echo test"
    assert_response "test", after: message
  end

  test "running the st-echo command without permission", %{user: user} do
    message = send_message user, "@deckard: operable:st-echo test"
    assert_response "@botci Sorry, you aren't allowed to execute 'operable:st-echo test' :(\n You will need the 'operable:st-echo' permission to run this command.", after: message
  end

  test "running commands in a pipeline", %{user: user} do
    user
    |> with_permission("operable:echo")
    |> with_permission("operable:thorn")

    message = send_message user, ~s(@deckard: operable:echo "this is a test" | operable:thorn $body)
    assert_response "þis is a test", after: message
  end

  test "running commands in a pipeline without permission", %{user: user} do
    user |> with_permission("operable:echo")

    message = send_message user, ~s(@deckard: operable:echo "this is a test" | operable:thorn $body)
    assert_response "@botci Sorry, you aren't allowed to execute 'operable:thorn $body' :(\n You will need the 'operable:thorn' permission to run this command.", after: message
  end
end
