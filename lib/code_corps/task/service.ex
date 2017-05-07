defmodule CodeCorps.Task.Service do
  @moduledoc """
  Handles special CRUD operations for `CodeCorps.Task`.
  """

  alias CodeCorps.{GitHub, Task, Repo}
  alias Ecto.{Changeset, Multi}

  @doc ~S"""
  Performs all actions involved in creating a task on a project
  """
  @spec create(map) :: {:ok, Task.t} | {:error, Changeset.t} | {:error, :github}
  def create(%{} = attributes) do
    multi =
      Multi.new
      |> Multi.insert(:task, %Task{} |> Task.create_changeset(attributes))
      |> Multi.run(:github, (fn %{task: %Task{} = task} -> task |> connect_to_github end))

    case multi |> Repo.transaction do
      # everything went great
      {:ok, %{github: %Task{} = task}} -> {:ok, task}
      # validation error on initial task insertion
      {:error, :task, %Changeset{} = changeset, _steps} -> {:error, changeset}
      # github API request error
      {:error, :github, _value, _steps} -> {:error, :github}
    end
  end

  @spec update(Task.t, map) :: {:ok, Task.t} | {:error, Changeset.t}
  def update(%Task{} = task, %{} = attributes) do
    task |> Task.update_changeset(attributes) |> Repo.update
  end

  @spec connect_to_github(Task.t) :: {:ok, Task.t} :: {:error, any}
  defp connect_to_github(%Task{github_repo_id: nil} = task), do: {:ok, task}
  defp connect_to_github(%Task{github_repo_id: _} = task) do
    with {:ok, issue} <- task |> Repo.preload([:github_repo, :user]) |> GitHub.Issue.create do
      task |> link_with_github_changeset(issue) |> Repo.update
    else
      {:error, github_error} -> {:error, github_error}
    end
  end

  @spec link_with_github_changeset(Task.t, map) :: Changeset.t
  defp link_with_github_changeset(%Task{} = task, %{"number" => number}) do
    task |> Changeset.change(%{github_issue_number: number})
  end
end
