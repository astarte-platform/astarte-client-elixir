#
# This file is part of Astarte.
#
# Copyright 2021-2022 SECO Mind
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
  @moduledoc """
  Module to manage groups.

  Astarte Groups documentation https://docs.astarte-platform.org/latest/065-groups.html
  """
  @moduledoc since: "0.1.0"

  alias Astarte.Client.{APIError, AppEngine}
  alias Astarte.Client.AppEngine.Pagination

  @doc """
  Returns the list of device groups.

  ## Examples

      Astarte.Client.AppEngine.Groups.list(client)

  """
  @doc since: "0.1.0"
  def list(%AppEngine{} = client) do
    request_path = "groups"
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
  Create a new group with a set of devices.

  Devices must already be registered in the realm.

  ## Examples

      Astarte.Client.AppEngine.Groups.create(client, group_name, [device_id1, device_id2])

  """
  @doc since: "0.1.0"
  def create(%AppEngine{} = client, group_name, devices)
      when is_binary(group_name) and is_list(devices) do
    request_path = "groups"
    tesla_client = client.http_client
    body = %{data: %{group_name: group_name, devices: devices}}

    with {:ok, %Tesla.Env{} = result} <- Tesla.post(tesla_client, request_path, body) do
      if result.status == 201 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  @doc """
  Returns the configuration of the group.

  Can be used to verify if a group exists.
  """
  @doc since: "0.1.0"
  def get(%AppEngine{} = client, group_name) when is_binary(group_name) do
    request_path = "groups/#{group_name}"
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
  Returns the list of devices in a group.

  ## Options

    * `:query` - list of query params

  ## Query options

    * `:details` - what data to return for every device. The possible values are:
      * `false` (default) - return device ID only
      * `true` - return detailed device status


  ## Examples

      Astarte.Client.AppEngine.Groups.get_devices(client, group_name)

      Astarte.Client.AppEngine.Groups.get_devices(client, group_name, query: [details: true])

  """
  @doc since: "0.1.0"
  def get_devices(%AppEngine{} = client, group_name, opts \\ [])
      when is_binary(group_name) do
    request_path = "groups/#{group_name}/devices"
    Pagination.list(client, request_path, opts)
  end

  @doc """
  Adds an existing device to a group.
  """
  @doc since: "0.1.0"
  def add_device(%AppEngine{} = client, group_name, device_id)
      when is_binary(group_name) and is_binary(device_id) do
    request_path = "groups/#{group_name}/devices"
    tesla_client = client.http_client
    body = %{data: %{device_id: device_id}}

    with {:ok, %Tesla.Env{} = result} <- Tesla.post(tesla_client, request_path, body) do
      if result.status == 201 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  @doc """
  Removes device from group.
  """
  @doc since: "0.1.0"
  def remove_device(%AppEngine{} = client, group_name, device_id)
      when is_binary(group_name) and is_binary(device_id) do
    request_path = "groups/#{group_name}/devices/#{device_id}"
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
