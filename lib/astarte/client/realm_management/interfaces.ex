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

defmodule Astarte.Client.RealmManagement.Interfaces do
  @moduledoc """
  Module to manage interfaces.

  Astarte Interfaces documentation https://docs.astarte-platform.org/latest/030-interface.html
  """
  @moduledoc since: "0.1.0"

  alias Astarte.Client.{APIError, RealmManagement}

  @doc """
  Returns the list of all installed interface names.

  ## Examples

      Astarte.Client.RealmManagement.Interfaces.list(client)

  """
  @doc since: "0.1.0"
  def list(%RealmManagement{} = client) do
    request_path = "interfaces"
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
  Returns the list of all major versions for given interface.

  ## Examples

      Astarte.Client.RealmManagement.Interfaces.list_major_versions(client, interface_name)

  """
  @doc since: "0.1.0"
  def list_major_versions(%RealmManagement{} = client, interface_name)
      when is_binary(interface_name) do
    request_path = "interfaces/#{interface_name}"
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
  Returns a previously installed interface.

  Previous minor versions for a given major version are not retrieved,
  only the most recent interface for each interface major is returned.

  ## Examples

      Astarte.Client.RealmManagement.Interfaces.get(client, interface_name, major_version)

  """
  @doc since: "0.1.0"
  def get(%RealmManagement{} = client, interface_name, major_version)
      when is_binary(interface_name) and is_integer(major_version) do
    request_path = "interfaces/#{interface_name}/#{major_version}"
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
  Create a new installed interface or a newer major version for a given interface.

  ## Options

    * `:query` - list of query params

  ## Query options

    * `:async_operation` - whether the operation should be carried out asynchronously
    The possible values are:
      * `true` (default)
      * `false`

  ## Examples

      Astarte.Client.RealmManagement.Interfaces.create(client, data)

      Astarte.Client.RealmManagement.Interfaces.create(client, data, query: [async_operation: false])

  """
  @doc since: "0.1.0"
  def create(%RealmManagement{} = client, data, opts \\ []) do
    request_path = "interfaces"
    tesla_client = client.http_client
    query = Keyword.get(opts, :query, [])

    with {:ok, %Tesla.Env{} = result} <-
           Tesla.post(tesla_client, request_path, %{data: data}, query: query) do
      if result.status == 201 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  @doc """
  Update an existing interface.

  Replaces an existing interface with a given major version with a new one
  (that must have same major version and a higher minor version).

  ## Options

    * `:query` - list of query params

  ## Query options

    * `:async_operation` - whether the operation should be carried out asynchronously
    The possible values are:
      * `true` (default)
      * `false`

  ## Examples

      Astarte.Client.RealmManagement.Interfaces.update(client, interface_name, major_version, data)

      Astarte.Client.RealmManagement.Interfaces.update(client, interface_name, major_version,
        data, query: [async_operation: false])

  """
  @doc since: "0.1.0"
  def update(%RealmManagement{} = client, interface_name, major_version, data, opts \\ [])
      when is_binary(interface_name) and is_integer(major_version) do
    request_path = "interfaces/#{interface_name}/#{major_version}"
    tesla_client = client.http_client
    query = Keyword.get(opts, :query, [])

    with {:ok, %Tesla.Env{} = result} <-
           Tesla.put(tesla_client, request_path, %{data: data}, query: query) do
      if result.status == 204 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  @doc """
  Deletes an existing interface draft.

  ## Options

    * `:query` - list of query params

  ## Query options

    * `:async_operation` - whether the operation should be carried out asynchronously
    The possible values are:
      * `true` (default)
      * `false`

  ## Examples

      Astarte.Client.RealmManagement.Interfaces.delete(client, interface_name, major_version)

      Astarte.Client.RealmManagement.Interfaces.delete(client, interface_name, major_version,
        query: [async_operation: false])

  """
  @doc since: "0.1.0"
  def delete(%RealmManagement{} = client, interface_name, major_version, opts \\ [])
      when is_binary(interface_name) and is_integer(major_version) do
    request_path = "interfaces/#{interface_name}/#{major_version}"
    tesla_client = client.http_client
    query = Keyword.get(opts, :query, [])

    with {:ok, %Tesla.Env{} = result} <- Tesla.delete(tesla_client, request_path, query: query) do
      if result.status == 204 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end
end
