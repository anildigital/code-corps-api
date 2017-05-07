defmodule CodeCorps.GitHub.FailureAPI do
  @moduledoc ~S"""
  A basic GitHub API mock which returns a 401 forbidden for all requests.

  Should be good enough for any tests that simply assert a piece of code is able
  to recover from a generic request error.

  For any tests that cover handling of specific errors, a non-default API should
  be defined inline.
  """
  import CodeCorps.GitHub.TestHelpers

  def request(method, url, headers, body, options) do
    send(self(), {method, url, headers, body, options})
    body = load_endpoint_fixture("forbidden")
    error = CodeCorps.GitHub.APIError.new({401, body})
    {:error, error}
  end
end
