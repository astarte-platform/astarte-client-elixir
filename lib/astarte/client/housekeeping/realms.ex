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

defmodule Astarte.Client.Housekeeping.Realms do
  alias Astarte.Client.{APIError, Housekeeping}

  def list(%Housekeeping{} = client) do
    request_path = "realms"
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
  Creates a new realm.

  ## Examples

    Astarte.Client.Housekeeping.Realms.create(client, realm_name, public_key_pem)

    Astarte.Client.Housekeeping.Realms.create(client, realm_name, public_key_pem, query: [async_operation: false])

  """
  def create(%Housekeeping{} = client, realm_name, public_key_pem, opts)
      when is_binary(realm_name) and is_binary(public_key_pem) and is_list(opts) do
    request_path = "realms"
    tesla_client = client.http_client
    query = Keyword.get(opts, :query, [])

    data = %{
      realm_name: realm_name,
      jwt_public_key_pem: public_key_pem
    }

    with {:ok, replication_data} <- fetch_replication(opts),
         realm_data = Map.merge(data, replication_data),
         {:ok, %Tesla.Env{} = result} <-
           Tesla.post(tesla_client, request_path, %{data: realm_data}, query: query) do
      if result.status == 201 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end

  @doc false
  def fetch_replication(opts) do
    with :error <- fetch_datacenter_replication(opts),
         :error <- fetch_simple_replication(opts) do
      {:error, :missing_replication}
    end
  end

  defp fetch_datacenter_replication(opts) do
    case Keyword.fetch(opts, :datacenter_replication_factors) do
      {:ok, replication_factors}
      when is_map(replication_factors) and map_size(replication_factors) > 0 ->
        replication = %{
          datacenter_replication_factors: replication_factors,
          replication_class: "NetworkTopologyStrategy"
        }

        {:ok, replication}

      {:ok, _other} ->
        {:error, :datacenter_replication_factor_invalid_format}

      :error ->
        :error
    end
  end

  defp fetch_simple_replication(opts) do
    case Keyword.fetch(opts, :replication_factor) do
      {:ok, replication_factor} when is_integer(replication_factor) and replication_factor > 0 ->
        replication = %{
          replication_factor: replication_factor,
          replication_class: "SimpleStrategy"
        }

        {:ok, replication}

      {:ok, _other} ->
        {:error, :replication_factor_invalid_format}

      :error ->
        :error
    end
  end

  def get(%Housekeeping{} = client, realm_name) when is_binary(realm_name) do
    request_path = "realms/#{realm_name}"
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
  Deletes a realm.

  ## Examples

    Astarte.Client.Housekeeping.Realms.delete(client, realm_name)

    Astarte.Client.Housekeeping.Realms.delete(client, realm_name, query: [async_operation: false])

  """
  def delete(%Housekeeping{} = client, realm_name, opts \\ []) when is_binary(realm_name) do
    request_path = "realms/#{realm_name}"
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
