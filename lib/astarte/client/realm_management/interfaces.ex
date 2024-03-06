#
# This file is part of Astarte.
#
# Copyright 2022-2023 SECO Mind
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
  alias Astarte.Client.{APIError, RealmManagement}

  def list(%RealmManagement{} = client) do
    request_path = "interfaces"

    with {:ok, tesla_client} <- RealmManagement.fetch_tesla_client(client),
         {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def list_major_versions(%RealmManagement{} = client, interface_name)
      when is_binary(interface_name) do
    request_path = "interfaces/#{interface_name}"

    with {:ok, tesla_client} <- RealmManagement.fetch_tesla_client(client),
         {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def get(%RealmManagement{} = client, interface_name, major_version)
      when is_binary(interface_name) and is_integer(major_version) do
    request_path = "interfaces/#{interface_name}/#{major_version}"

    with {:ok, tesla_client} <- RealmManagement.fetch_tesla_client(client),
         {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def create(%RealmManagement{} = client, data, opts \\ []) do
    request_path = "interfaces"
    query = Keyword.get(opts, :query, [])

    with {:ok, tesla_client} <- RealmManagement.fetch_tesla_client(client),
         {:ok, %Tesla.Env{} = result} <-
           Tesla.post(tesla_client, request_path, %{data: data}, query: query) do
      if result.status == 201 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def update(%RealmManagement{} = client, interface_name, major_version, data, opts \\ [])
      when is_binary(interface_name) and is_integer(major_version) do
    request_path = "interfaces/#{interface_name}/#{major_version}"
    query = Keyword.get(opts, :query, [])

    with {:ok, tesla_client} <- RealmManagement.fetch_tesla_client(client),
         {:ok, %Tesla.Env{} = result} <-
           Tesla.put(tesla_client, request_path, %{data: data}, query: query) do
      if result.status == 204 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def delete(%RealmManagement{} = client, interface_name, major_version, opts \\ [])
      when is_binary(interface_name) and is_integer(major_version) do
    request_path = "interfaces/#{interface_name}/#{major_version}"
    query = Keyword.get(opts, :query, [])

    with {:ok, tesla_client} <- RealmManagement.fetch_tesla_client(client),
         {:ok, %Tesla.Env{} = result} <- Tesla.delete(tesla_client, request_path, query: query) do
      if result.status == 204 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end
end
