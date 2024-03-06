#
# This file is part of Astarte.
#
# Copyright 2021-2023 SECO Mind
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

defmodule Astarte.Client.AppEngine.Groups do
  alias Astarte.Client.{APIError, AppEngine}
  alias Astarte.Client.AppEngine.Pagination

  def list(%AppEngine{} = client) do
    request_path = "groups"

    with {:ok, tesla_client} <- AppEngine.fetch_tesla_client(client),
         {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def create(%AppEngine{} = client, group_name, devices)
      when is_binary(group_name) and is_list(devices) do
    request_path = "groups"
    body = %{data: %{group_name: group_name, devices: devices}}

    with {:ok, tesla_client} <- AppEngine.fetch_tesla_client(client),
         {:ok, %Tesla.Env{} = result} <- Tesla.post(tesla_client, request_path, body) do
      if result.status == 201 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def get(%AppEngine{} = client, group_name) when is_binary(group_name) do
    request_path = "groups/#{group_name}"

    with {:ok, tesla_client} <- AppEngine.fetch_tesla_client(client),
         {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  @doc """

  ## Examples
  Astarte.Client.AppEngine.Groups.get_devices(client, group_name)

  Astarte.Client.AppEngine.Groups.get_devices(client, group_name, query: [details: true])
  """
  def get_devices(%AppEngine{} = client, group_name, opts \\ [])
      when is_binary(group_name) do
    request_path = "groups/#{group_name}/devices"
    Pagination.list(client, request_path, opts)
  end

  def add_device(%AppEngine{} = client, group_name, device_id)
      when is_binary(group_name) and is_binary(device_id) do
    request_path = "groups/#{group_name}/devices"
    body = %{data: %{device_id: device_id}}

    with {:ok, tesla_client} <- AppEngine.fetch_tesla_client(client),
         {:ok, %Tesla.Env{} = result} <- Tesla.post(tesla_client, request_path, body) do
      if result.status == 201 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def remove_device(%AppEngine{} = client, group_name, device_id)
      when is_binary(group_name) and is_binary(device_id) do
    request_path = "groups/#{group_name}/devices/#{device_id}"

    with {:ok, tesla_client} <- AppEngine.fetch_tesla_client(client),
         {:ok, %Tesla.Env{} = result} <- Tesla.delete(tesla_client, request_path) do
      if result.status == 204 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end
end
