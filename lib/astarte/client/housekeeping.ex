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

defmodule Astarte.Client.Housekeeping do
  @moduledoc """
  Module to configure communication with Astarte Housekeeping API.

  Housekeeping is the equivalent of a superadmin API.
  It allows to manage and create realms, perform cluster-wide maintenance actions.
  This API is usually accessible only to system administrators, and is not meant for the average user of Astarte,
  which should refer to `Astarte.Client.RealmManagement` instead.
  """
  @moduledoc since: "0.1.0"

  alias Astarte.Client.Credentials

  @jwt_expiry 5 * 60
  @enforce_keys [:http_client]

  defstruct @enforce_keys

  @type t :: %__MODULE__{
          http_client: Tesla.Client.t()
        }

  @doc """
  Returns configured `Astarte.Client.Housekeeping` struct.

  This function receives Astarte base API URL alongside authentication options
  and returns configured `Astarte.Client.Housekeeping` struct.

  ## Options

  One of `:jwt` and `:private_key` options is required.

    * `:jwt` - JWT for Bearer authentication, if used `:private_key` and `:jwt_opts` are ignored

    * `:private_key` - will be used to generate JWT, this option is mutually exclusive
    with `:jwt`, if the latter is used, this option will be ignored.

    * `:jwt_opts` - will add additional JWT claims to generated JWT, this option is mutually exclusive
    with `:jwt`, if the latter is used, this option will be ignored.

  ## JWT options

  The accepted options for `:jwt_opts` are:

    * `:issuer`  - the "iss" (issuer) claim

    * `:subject` - the "sub" (subject) claim

    * `:expiry` - how to generate the "exp" (expiration time) claim. The possible values are:
      * `:infinity` - do not add expiration time claim
      * `positive integer` - the amount of time in seconds to be added to the current time
      at JWT generation moment

  ## Examples

      Astarte.Client.Housekeeping.new("https://api.eu1.astarte.cloud", jwt: jwt)

      Astarte.Client.Housekeeping.new("https://api.eu1.astarte.cloud", private_key: private_key)

      Astarte.Client.Housekeeping.new("https://api.eu1.astarte.cloud",
        private_key: private_key,
        jwt_opts: [issuer: "foo", subject: "bar", expiry: :infinity]
      )

  """
  @doc since: "0.1.0"
  @spec new(String.t(), Keyword.t()) :: {:ok, t()} | {:error, any}
  def new(base_api_url, opts) when is_binary(base_api_url) and is_list(opts) do
    with {:ok, jwt} <- fetch_or_generate_jwt(opts) do
      base_url = Path.join([base_api_url, "housekeeping", "v1"])

      middleware = [
        {Tesla.Middleware.BaseUrl, base_url},
        Tesla.Middleware.JSON,
        {Tesla.Middleware.Headers, [{"Authorization", "Bearer: " <> jwt}]}
      ]

      http_client = Tesla.client(middleware)
      {:ok, %__MODULE__{http_client: http_client}}
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
        |> Credentials.housekeeping_all_access_credentials()
        |> Credentials.to_jwt(private_key)

      :error ->
        {:error, :missing_private_key}
    end
  end
end
