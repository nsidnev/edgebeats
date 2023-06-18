defmodule LiveBeatsWeb.GithubCallbackTest do
  use LiveBeatsWeb.ConnCase, async: false

  alias LiveBeats.Accounts

  def exchange_access_token(opts) do
    _code = opts[:code]
    state = opts[:state]

    case state do
      "valid" ->
        {:ok,
         %{
           info: %{
             "login" => "chrismccord",
             "name" => "Chris",
             "id" => 1,
             "avatar_url" => "",
             "html_url" => ""
           },
           primary_email: "chris@local.test",
           emails: [%{"primary" => true, "email" => "chris@local.test"}],
           token: "1234"
         }}

      "invalid" ->
        {:error, %{reason: "token"}}

      "failed" ->
        {:error, %{reason: state}}
    end
  end

  setup %{conn: conn} do
    conn = assign(conn, :github_client, __MODULE__)

    {:ok, conn: conn}
  end

  test "callback with valid token", %{conn: conn} do
    params = %{"code" => "66e1c4202275d071eced", "state" => "valid"}

    assert Accounts.get_user_by_username("chrismccord") == nil

    conn = get(conn, ~p"/oauth/callbacks/github?#{params}")

    assert redirected_to(conn, 302) == "/chrismccord"
    assert %Accounts.User{} = user = Accounts.get_user_by_username!("chrismccord")
    assert user.name == "Chris"
  end

  test "callback with invalid exchange response", %{conn: conn} do
    params = %{"code" => "66e1c4202275d071eced", "state" => "invalid"}
    conn = get(conn, ~p"/oauth/callbacks/github?#{params}")

    assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
             "We were unable to contact GitHub. Please try again later"

    assert redirected_to(conn, 302) == "/"
    refute Accounts.get_user_by_username("chrismccord")
  end

  test "callback with failed token exchange", %{conn: conn} do
    params = %{"code" => "66e1c4202275d071eced", "state" => "failed"}
    conn = get(conn, ~p"/oauth/callbacks/github?#{params}")

    assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
             "We were unable to contact GitHub. Please try again later"

    assert redirected_to(conn, 302) == "/"
    refute Accounts.get_user_by_username("chrismccord")
  end
end
