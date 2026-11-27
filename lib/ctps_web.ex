defmodule CtpsWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use CtpsWeb, :controller
      use CtpsWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def controller do
    quote do
      use Phoenix.Controller, formats: [:html, :json]

      use Gettext, backend: CtpsWeb.Gettext

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView

      unquote(live_view_helpers())

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(live_view_helpers())

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # Translation
      use Gettext, backend: CtpsWeb.Gettext

      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components
      import CtpsWeb.CoreComponents

      # Common modules used in templates
      alias Phoenix.LiveView.JS
      alias CtpsWeb.Layouts

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: CtpsWeb.Endpoint,
        router: CtpsWeb.Router,
        statics: CtpsWeb.static_paths()
    end
  end

  def live_view_helpers do
    quote do
      @type socket :: Phoenix.LiveView.Socket.t()
      @type rendered :: Phoenix.LiveView.Rendered.t()

      @doc """
      Monad-aware `assign`.

      Takes a keyword list of `{key, monadic_value}` pairs (or a single
      `key, monadic_value` pair) and either assigns the unwrapped value on
      `{:ok, _}` or accumulates the `%Shared.ErrorM{}` under the `:errorM`
      assign so the view can render it.

      ## Examples

          socket
          |> assignM(classes: Classes.list(), bgs: Backgrounds.list())

          socket |> assignM(:user, Users.get_one(id))
      """
      @spec assignM(socket(), keyword(Shared.Monad.m(any()))) :: socket()
      def assignM(socket, pairs) when is_list(pairs) do
        Enum.reduce(pairs, socket, fn {key, monad}, acc ->
          assignM(acc, key, monad)
        end)
      end

      @spec assignM(socket(), atom(), Shared.Monad.m(any())) :: socket()
      def assignM(socket, key, {:ok, value}), do: assign(socket, key, value)

      def assignM(socket, _key, %Shared.ErrorM{} = error) do
        errors = socket.assigns[:errorM] || []
        assign(socket, errorM: [error | errors])
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/live_view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
