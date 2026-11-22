defmodule CtpsWeb.PageController do
  use CtpsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
