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

defmodule Astarte.Client.Housekeeping do
  @enforce_keys [:http_client]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          http_client: Tesla.Client.t()
        }

  alias __MODULE__
  alias Astarte.Client.Credentials

  @jwt_expiry 5 * 60

  @spec new(String.t(), Keyword.t()) :: {:ok, t()} | {:error, any}
  def new(base_api_url, opts) when is_binary(base_api_url) and is_list(opts) do
    with {:ok, jwt} <- fetch_jwt(opts) do
      base_url = Path.join([base_api_url, "housekeeping", "v1"])

      middleware = [
        {Tesla.Middleware.BaseUrl, base_url},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Headers, [{"Authorization", "Bearer: " <> jwt}]}
      ]

      http_client = Tesla.client(middleware)
      {:ok, %Housekeeping{http_client: http_client}}
    end
  end

  defp fetch_jwt(opts) do
    with :error <- Keyword.fetch(opts, :jwt) do
      opts
      |> Keyword.get(:private_key)
      |> generate_jwt()
    end
  end

  defp generate_jwt(nil = _private_key) do
    {:error, :missing_jwt_and_private_key}
  end

  defp generate_jwt(private_key) when is_binary(private_key) do
    Credentials.housekeeping_all_access_credentials(expiry: @jwt_expiry)
    |> Credentials.to_jwt(private_key)
  end
end
