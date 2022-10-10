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

defmodule Astarte.Client.AppEngine.Devices do
  @moduledoc """
  Module to interact with devices, send and receive data.
  """
  @moduledoc since: "0.1.0"

  alias Astarte.Client.{APIError, AppEngine}
  alias Astarte.Client.AppEngine.Pagination

  @doc """
  Returns the list of all devices.

  By default the device ID string is returned for each already registered device.
  The complete device status can be optionally retrieved rather than device ID string using details option.

  ## Options

    * `:query` - list of query params

  ## Query options

    * `:details` - what data to return for every device. The possible values are:
      * `false` (default) - return device ID only
      * `true` - return detailed device status

  ## Examples

      Astarte.Client.AppEngine.Devices.list(client)

      Astarte.Client.AppEngine.Devices.list(client, query: [details: true])

  """
  @doc since: "0.1.0"
  def list(%AppEngine{} = client, opts \\ []) do
    Pagination.list(client, "devices", opts)
  end

  @doc """
  Returns the device overview status.

  Overview includes an array of reported interfaces (introspection), offline/online status, etc.

  ## Examples

      Astarte.Client.AppEngine.Devices.get_device_status(client, "hm8AjtbN5P2mxo_gfXSfvQ")

  """
  @doc since: "0.1.0"
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

  @doc """
  Returns a list of interfaces supported by a certain device.

  Interfaces that are not reported by the device are not reported here.
  If a device stops to advertise a certain interface, it should be retrived from a different API,
  same applies for older versions of a certain interface.

  ## Examples

      Astarte.Client.AppEngine.Devices.get_device_interfaces(client, "hm8AjtbN5P2mxo_gfXSfvQ")

  """
  @doc since: "0.1.0"
  def get_device_interfaces(%AppEngine{} = client, device_id) when is_binary(device_id) do
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

  @doc """
  Returns a values snapshot for a given interface without `:path` option, otherwise
  returns a value on a given endpoint path.

  ## Options

    * `:path`  - endpoint path

    * `:query` - list of query params

  """
  @doc since: "0.1.0"
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

  @doc """
  Update a property value on a given endpoint path.

  Interface should be an individual server owned property interface.
  """
  @doc since: "0.1.0"
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

  @doc """
  Unset a value on a given endpoint path, path is also deleted.

  Interface should be an individual server owned property interface and to support unset.
  """
  @doc since: "0.1.0"
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

  @doc """
  Returns values for a given datastream interface.

  ## Options

    * `:path` - endpoint path

    * `:query` - list of query params

  ## Query options
    * `:since` - query all values since a certain timestamp (all entries where timestamp >= `:since`).
    It must be a ISO 8601 valid timestamp.
    This option is mutually exclusive with `:since_after`.

    * `:since_after` - query all values since after a certain timestamp (all entries where timestamp > `:since_after`).
    It must be a ISO 8601 valid timestamp.
    This option is mutually exclusive with `:since`.

    * `:to` - query all values up to a certain timestamp.
    It must be a ISO 8601 valid timestamp.
    If `:since` and `:since_after` are not specified first entry date is assumed by default.

    * `:limit` - limit number of retrieved data production entries to `:limit`.
    This parameter must be always specified when `:since`, `:since_after` and `:to` query parameters are used.
    If limit is specified without `:since`, `:since_after` and `:to` parameters, last `:limit` values are retrieved.
    When `:limit` entries are returned, it should be checked if any other entry is left by using `:since_after` the last received timestamp.
    An error is returned if `:limit` exceeds maximum allowed value.

  """
  @doc since: "0.1.0"
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

  @doc """
  Sends data to a given datastream interface path.
  """
  @doc since: "0.1.0"
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
end
