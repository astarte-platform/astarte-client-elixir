#
# This file is part of Astarte.
#
# Copyright 2022 SECO Mind
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

defmodule Astarte.Client.RealmManagement.Triggers do
  @moduledoc """
  Module to manage triggers.

  Astarte Triggers documentation https://docs.astarte-platform.org/latest/060-triggers.html
  """
  @moduledoc since: "0.1.0"

  alias Astarte.Client.{APIError, RealmManagement}

  @doc """
  Returns the list of all installed triggers.

  ## Examples

      Astarte.Client.RealmManagement.Triggers.list(client)

  """
  @doc since: "0.1.0"
  def list(%RealmManagement{} = client) do
    request_path = "triggers"
    tesla_client = client.http_client

    with {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  @doc """
  Returns a previously installed trigger.

  ## Examples

      Astarte.Client.RealmManagement.Triggers.get(client, trigger_name)

  """
  @doc since: "0.1.0"
  def get(%RealmManagement{} = client, trigger_name) when is_binary(trigger_name) do
    request_path = "triggers/#{trigger_name}"
    tesla_client = client.http_client

    with {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  @doc """
  Create a new trigger using provided configuration.

  Trigger validation is performed before installation, if trigger configuration is not valid or
  a trigger with the same name already exists an error is reported.

  ## Examples

      Astarte.Client.RealmManagement.Triggers.create(client, data)

  """
  @doc since: "0.1.0"
  def create(%RealmManagement{} = client, data) do
    request_path = "triggers"
    tesla_client = client.http_client

    with {:ok, %Tesla.Env{} = result} <- Tesla.post(tesla_client, request_path, %{data: data}) do
      if result.status == 201 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  @doc """
  Deletes an existing trigger.

  ## Examples

      Astarte.Client.RealmManagement.Triggers.create(client, trigger_name)

  """
  @doc since: "0.1.0"
  def delete(%RealmManagement{} = client, trigger_name) when is_binary(trigger_name) do
    request_path = "triggers/#{trigger_name}"
    tesla_client = client.http_client

    with {:ok, %Tesla.Env{} = result} <- Tesla.delete(tesla_client, request_path) do
      if result.status == 204 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end
end
