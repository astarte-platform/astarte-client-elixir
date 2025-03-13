#
# This file is part of Astarte.
#
# Copyright 2021 SECO Mind
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

defmodule Astarte.Client.AppEngine.Devices do
  alias Astarte.Client.{APIError, AppEngine}
  alias Astarte.Client.AppEngine.Pagination

  @doc """

  ## Examples
  Astarte.Client.AppEngine.Devices.list(client)

  Astarte.Client.AppEngine.Devices.list(client, query: [details: true])
  """
  def list(%AppEngine{} = client, opts \\ []) do
    Pagination.list(client, "devices", opts)
  end

  def get_device_status(%AppEngine{} = client, device_id) when is_binary(device_id) do
    request_path = "devices/#{device_id}"
    tesla_client = client.http_client

    with {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def get_device_interfaces(%AppEngine{} = client, device_id) do
    request_path = "devices/#{device_id}/interfaces"
    tesla_client = client.http_client

    with {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def get_properties_data(%AppEngine{} = client, device_id, interface, opts \\ [])
      when is_binary(device_id) and is_binary(interface) do
    tesla_client = client.http_client
    query = Keyword.get(opts, :query, [])

    request_path =
      if path = opts[:path] do
        "devices/#{device_id}/interfaces/#{interface}#{path}"
      else
        "devices/#{device_id}/interfaces/#{interface}"
      end

    with {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path, query: query) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def set_property(%AppEngine{} = client, device_id, interface, path, data)
      when is_binary(device_id) and is_binary(interface) and is_binary(path) do
    tesla_client = client.http_client
    request_path = "devices/#{device_id}/interfaces/#{interface}#{path}"

    with {:ok, %Tesla.Env{} = result} <- Tesla.put(tesla_client, request_path, %{data: data}) do
      if result.status == 200 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def unset_property(%AppEngine{} = client, device_id, interface, path)
      when is_binary(device_id) and is_binary(interface) and is_binary(path) do
    tesla_client = client.http_client
    request_path = "devices/#{device_id}/interfaces/#{interface}#{path}"

    with {:ok, %Tesla.Env{} = result} <- Tesla.delete(tesla_client, request_path) do
      if result.status == 204 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def get_datastream_data(%AppEngine{} = client, device_id, interface, opts \\ [])
      when is_binary(device_id) and is_binary(interface) do
    tesla_client = client.http_client
    query = Keyword.get(opts, :query, [])

    request_path =
      if path = opts[:path] do
        "devices/#{device_id}/interfaces/#{interface}#{path}"
      else
        "devices/#{device_id}/interfaces/#{interface}"
      end

    with {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path, query: query) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  def send_datastream(%AppEngine{} = client, device_id, interface, path, data)
      when is_binary(device_id) and is_binary(interface) and is_binary(path) do
    tesla_client = client.http_client
    request_path = "devices/#{device_id}/interfaces/#{interface}#{path}"

    with {:ok, %Tesla.Env{} = result} <- Tesla.post(tesla_client, request_path, %{data: data}) do
      if result.status == 200 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  @doc """
  Update a writable property of a device.
  """
  def update_device_writeable_property(%AppEngine{} = client, device_id, data) do
    tesla_client = client.http_client
    request_path = "devices/#{device_id}"
    headers = [{"content-type", "application/merge-patch+json"}]

    with {:ok, %Tesla.Env{} = result} <-
           Tesla.patch(tesla_client, request_path, %{data: data}, headers: headers) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end
end
