defmodule CodeCorps.Task.ServiceTest do
  use CodeCorps.DbAccessCase

  import CodeCorps.GitHub.TestHelpers

  alias CodeCorps.Task

  @base_attrs %{
    "title" => "Test task",
    "markdown" => "A test task",
    "status" => "open"
  }

  defp valid_attrs() do
    project = insert(:project)
    task_list = insert(:task_list, project: project, inbox: true)
    user = insert(:user)

    @base_attrs
    |> Map.put("project_id", project.id)
    |> Map.put("task_list_id", task_list.id)
    |> Map.put("user_id", user.id)
  end

  describe "create/2" do
    test "creates task" do
      {:ok, task} = valid_attrs() |> Task.Service.create

      assert task.title == @base_attrs["title"]
      assert task.markdown == @base_attrs["markdown"]
      assert task.body
      assert task.status == "open"
      refute task.github_issue_number
      refute task.github_repo_id

      refute_received({:post, _string, {}, "{}", []})
    end

    test "returns errored changeset if attributes are invalid" do
      {:error, changeset} = Task.Service.create(@base_attrs)
      refute changeset.valid?
      refute Repo.one(Task)

      refute_received({:post, _string, _headers, _body, _options})
    end

    test "if task is assigned a github repo, creates github issue on assigned repo" do
      attrs = valid_attrs()
      project = Repo.one(CodeCorps.Project)
      github_repo =
        :github_repo
        |> insert(github_account_login: "foo", name: "bar")

      insert(:project_github_repo, project: project, github_repo: github_repo)

      {:ok, task} =
        attrs
        |> Map.put("github_repo_id", github_repo.id)
        |> Task.Service.create

      assert task.title == @base_attrs["title"]
      assert task.markdown == @base_attrs["markdown"]
      assert task.body
      assert task.status == "open"
      assert task.github_issue_number
      assert task.github_repo_id == github_repo.id

      assert_received({:post, "https://api.github.com/repos/foo/bar/issues", _headers, _body, _options})
    end

    test "if github process fails, returns {:error, :github}" do
      attrs = valid_attrs()
      project = Repo.one(CodeCorps.Project)
      github_repo =
        :github_repo
        |> insert(github_account_login: "foo", name: "bar")

      insert(:project_github_repo, project: project, github_repo: github_repo)


      with_mock_api(CodeCorps.GitHub.FailureAPI) do
        assert {:error, :github} ==
          attrs
          |> Map.put("github_repo_id", github_repo.id)
          |> Task.Service.create
      end

      refute Repo.one(Task)
      assert_received({:post, "https://api.github.com/repos/foo/bar/issues", _headers, _body, _options})
    end
  end
end
