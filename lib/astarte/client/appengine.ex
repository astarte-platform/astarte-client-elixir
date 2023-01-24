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

defmodule Astarte.Client.AppEngine do
  alias Astarte.Client.Credentials

  @jwt_expiry 5 * 60
  @enforce_keys [:base_url, :opts]

  defstruct @enforce_keys

  @type jwt_option :: {:issuer, binary} | {:subject, binary} | {:expiry, pos_integer | :infinity}
  @type option :: {:jwt, binary} | {:private_key, binary} | {:jwt_opts, [jwt_option, ...]}
  @type t :: %__MODULE__{
          base_url: binary,
          opts: [option, ...]
        }

  @spec new(String.t(), String.t(), Keyword.t()) :: {:ok, t} | {:error, any}
  def new(base_api_url, realm_name, opts)
      when is_binary(base_api_url) and is_binary(realm_name) and is_list(opts) do
    with {:ok, _jwt} <- fetch_or_generate_jwt(opts) do
      base_url = Path.join([base_api_url, "appengine", "v1", realm_name])

      {:ok,
       %__MODULE__{
         base_url: base_url,
         opts: opts
       }}
    end
  end

  @doc false
  @spec fetch_tesla_client(t) :: {:ok, Tesla.Client.t()} | {:error, any}
  def fetch_tesla_client(%__MODULE__{} = appengine_client) do
    %__MODULE__{base_url: base_url, opts: opts} = appengine_client

    with {:ok, jwt} <- fetch_or_generate_jwt(opts) do
      middleware = [
        {Tesla.Middleware.BaseUrl, base_url},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Headers, [{"Authorization", "Bearer: " <> jwt}]}
      ]

      {:ok, Tesla.client(middleware)}
    end
  end

  defp fetch_or_generate_jwt(opts) when is_list(opts) do
    with {:error, :missing_jwt} <- fetch_jwt(opts),
         {:error, :missing_private_key} <- generate_jwt(opts) do
      {:error, :missing_jwt_and_private_key}
    end
  end

  defp fetch_jwt(opts) when is_list(opts) do
    case Keyword.fetch(opts, :jwt) do
      {:ok, jwt} when is_binary(jwt) ->
        {:ok, jwt}

      :error ->
        {:error, :missing_jwt}
    end
  end

  defp generate_jwt(opts) when is_list(opts) do
    case Keyword.fetch(opts, :private_key) do
      {:ok, private_key} when is_binary(private_key) ->
        opts
        |> Keyword.get(:jwt_opts, [])
        |> Keyword.put_new(:expiry, @jwt_expiry)
        |> Credentials.appengine_all_access_credentials()
        |> Credentials.to_jwt(private_key)

      :error ->
        {:error, :missing_private_key}
    end
  end
end
