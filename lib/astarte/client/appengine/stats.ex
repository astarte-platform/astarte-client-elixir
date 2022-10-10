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

defmodule Astarte.Client.AppEngine.Stats do
  @moduledoc """
  Module to retrieve devices stats
  """
  @moduledoc since: "0.1.0"

  alias Astarte.Client.{APIError, AppEngine}

  @doc """
  Returns stats regarding devices in a realm

  ## Example

      Astarte.Client.AppEngine.Stats.get_devices_stats(client)

  """
  @doc since: "0.1.0"
  def get_devices_stats(%AppEngine{} = client) do
    request_path = "stats/devices"
    tesla_client = client.http_client

    with {:ok, %Tesla.Env{} = result} <- Tesla.get(tesla_client, request_path) do
      if result.status == 200 do
        {:ok, result.body}
      else
        {:error, %APIError{status: result.status, response: result.body}}
      end
    end
  end
end
