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

defmodule Astarte.Client.RealmManagement.RealmConfig do
  @moduledoc """
  Module to configure the global behavior of the Realm and how it can be accessed.
  """
  @moduledoc since: "0.1.0"

  alias Astarte.Client.{APIError, RealmManagement}

  @doc """
  Returns the auth configuration of the realm.
  """
  @doc since: "0.1.0"
  def get_auth_config(%RealmManagement{} = client) do
    request_path = "config/auth"
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
  Installs an auth configuration for the realm.
  """
  @doc since: "0.1.0"
  def set_auth_config(%RealmManagement{} = client, data) do
    request_path = "config/auth"
    tesla_client = client.http_client

    with {:ok, %Tesla.Env{} = result} <- Tesla.put(tesla_client, request_path, %{data: data}) do
      if result.status == 204 do
        :ok
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end
end
