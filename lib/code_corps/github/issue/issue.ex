defmodule CodeCorps.GitHub.Issue do

  alias CodeCorps.{GitHub, GithubRepo, Task, User}

  @spec create(Task.t) :: GitHub.response
  def create(%Task{
    github_repo: %GithubRepo{} = github_repo,
    user: %User{} = user
    } = task) do

    endpoint = github_repo |> get_endpoint()
    attrs = task |> GitHub.Adapters.Task.to_issue

    make_request(user, :post, endpoint, attrs)
  end

  @spec get_endpoint(GithubRepo.r) :: String.t
  defp get_endpoint(%GithubRepo{github_account_login: owner, name: repo}) do
    "/repos/#{owner}/#{repo}/issues"
  end

  @spec make_request(User.t, atom, String.t, map) :: GitHub.response
  defp make_request(%User{github_auth_token: nil}, method, endpoint, %{} = attrs) do
    GitHub.integration_request(method, endpoint, %{}, attrs, [])
  end
  defp make_request(%User{github_auth_token: token}, method, endpoint, %{} = attrs) do
    GitHub.request(method, endpoint, %{}, attrs, [access_token: token])
  end
end
