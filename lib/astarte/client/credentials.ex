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

defmodule Astarte.Client.Credentials do
  @moduledoc """
  This module simplifies generation of JWT from private key.

  It also allows to add granular authorization claims.

  Astarte Authentication and Authorization documentation https://docs.astarte-platform.org/latest/070-auth.html
  """
  @moduledoc since: "0.1.0"

  require Record

  alias __MODULE__

  # Create an :ec_private_key record to easily extract the curve parameters from EC keys
  Record.defrecordp(
    :ec_private_key,
    Record.extract(:ECPrivateKey, from_lib: "public_key/include/public_key.hrl")
  )

  @api_all_access_claim_value ".*::.*"
  @default_expiry 5 * 60

  defstruct claims: %{},
            expiry: nil,
            issuer: nil,
            subject: nil

  @type t :: %__MODULE__{
          claims: map,
          expiry: pos_integer | :infinity,
          issuer: binary | nil,
          subject: binary | nil
        }

  @doc """
  Returns `Astarte.Client.Credentials` struct.
  """
  @doc since: "0.1.0"
  def new do
    %Credentials{}
  end

  @doc """
  Returns regular expression that allows any operation.
  """
  @doc since: "0.1.0"
  @spec api_all_access_claim_value() :: binary
  def api_all_access_claim_value do
    @api_all_access_claim_value
  end

  @doc """
  Returns configured `Astarte.Client.Credentials` struct having claims
  that allows any operation on AppEngine, Realm Management, Pairing,
  Flow APIs and Astarte Channels.

  ## Options

  The accepted options are:

    * `:issuer`  - the "iss" (issuer) claim

    * `:subject` - the "sub" (subject) claim

    * `:expiry` - how to generate the "exp" (expiration time) claim. The possible values are:
      * `:infinity` - do not add expiration time claim
      * `positive integer` - the amount of time in seconds to be added to the current time
      at JWT generation moment
  """
  @doc since: "0.1.0"
  @spec dashboard_credentials(keyword) :: t
  def dashboard_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_appengine_claim(@api_all_access_claim_value)
    |> append_realm_management_claim(@api_all_access_claim_value)
    |> append_pairing_claim(@api_all_access_claim_value)
    |> append_flow_claim(@api_all_access_claim_value)
    |> append_channels_claim("JOIN::.*")
    |> append_channels_claim("WATCH::.*")
    |> maybe_set_issuer(opts[:issuer])
    |> maybe_set_subject(opts[:subject])
    |> set_expiry(expiry)
  end

  @doc """
  Returns configured `Astarte.Client.Credentials` struct having claims
  that allows any operation on AppEngine API and Astarte Channels.

  ## Options

  The accepted options are:

    * `:issuer`  - the "iss" (issuer) claim

    * `:subject` - the "sub" (subject) claim

    * `:expiry` - how to generate the "exp" (expiration time) claim. The possible values are:
      * `:infinity` - do not add expiration time claim
      * `positive integer` - the amount of time in seconds to be added to the current time
      at JWT generation moment
  """
  @doc since: "0.1.0"
  @spec appengine_all_access_credentials(keyword) :: t
  def appengine_all_access_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_appengine_claim(@api_all_access_claim_value)
    |> append_channels_claim("JOIN::.*")
    |> append_channels_claim("WATCH::.*")
    |> maybe_set_issuer(opts[:issuer])
    |> maybe_set_subject(opts[:subject])
    |> set_expiry(expiry)
  end

  @doc """
  Returns configured `Astarte.Client.Credentials` struct having claims
  that allows any operation on Pairing API.

  ## Options

  The accepted options are:

    * `:issuer`  - the "iss" (issuer) claim

    * `:subject` - the "sub" (subject) claim

    * `:expiry` - how to generate the "exp" (expiration time) claim. The possible values are:
      * `:infinity` - do not add expiration time claim
      * `positive integer` - the amount of time in seconds to be added to the current time
      at JWT generation moment
  """
  @doc since: "0.1.0"
  @spec pairing_all_access_credentials(keyword) :: t
  def pairing_all_access_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_pairing_claim(@api_all_access_claim_value)
    |> maybe_set_issuer(opts[:issuer])
    |> maybe_set_subject(opts[:subject])
    |> set_expiry(expiry)
  end

  @doc """
  Returns configured `Astarte.Client.Credentials` struct having claims
  that allows any operation on Realm Management API.

  ## Options

  The accepted options are:

    * `:issuer`  - the "iss" (issuer) claim

    * `:subject` - the "sub" (subject) claim

    * `:expiry` - how to generate the "exp" (expiration time) claim. The possible values are:
      * `:infinity` - do not add expiration time claim
      * `positive integer` - the amount of time in seconds to be added to the current time
      at JWT generation moment
  """
  @doc since: "0.1.0"
  @spec realm_management_all_access_credentials(keyword) :: t
  def realm_management_all_access_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_realm_management_claim(@api_all_access_claim_value)
    |> maybe_set_issuer(opts[:issuer])
    |> maybe_set_subject(opts[:subject])
    |> set_expiry(expiry)
  end

  @doc """
  Returns configured `Astarte.Client.Credentials` struct having claims
  that allows any operation on Housekeeping API.

  ## Options

  The accepted options are:

    * `:issuer`  - the "iss" (issuer) claim

    * `:subject` - the "sub" (subject) claim

    * `:expiry` - how to generate the "exp" (expiration time) claim. The possible values are:
      * `:infinity` - do not add expiration time claim
      * `positive integer` - the amount of time in seconds to be added to the current time
      at JWT generation moment
  """
  @doc since: "0.1.0"
  @spec housekeeping_all_access_credentials(keyword) :: t
  def housekeeping_all_access_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_housekeeping_claim(@api_all_access_claim_value)
    |> maybe_set_issuer(opts[:issuer])
    |> maybe_set_subject(opts[:subject])
    |> set_expiry(expiry)
  end

  def astartectl_credentials(opts \\ []) do
    expiry = Keyword.get(opts, :expiry, @default_expiry)

    Credentials.new()
    |> append_appengine_claim(@api_all_access_claim_value)
    |> append_realm_management_claim(@api_all_access_claim_value)
    |> append_pairing_claim(@api_all_access_claim_value)
    |> append_flow_claim(@api_all_access_claim_value)
    |> maybe_set_issuer(opts[:issuer])
    |> maybe_set_subject(opts[:subject])
    |> set_expiry(expiry)
  end

  @doc """
  Appends claim for Housekeeping API
  """
  @doc since: "0.1.0"
  @spec append_housekeeping_claim(t, binary) :: t
  def append_housekeeping_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_ha", claim)
  end

  @doc """
  Appends claim for Realm Management API
  """
  @doc since: "0.1.0"
  @spec append_realm_management_claim(t, binary) :: t
  def append_realm_management_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_rma", claim)
  end

  @doc """
  Appends claim for Pairing API
  """
  @doc since: "0.1.0"
  @spec append_pairing_claim(t, binary) :: t
  def append_pairing_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_pa", claim)
  end

  @doc """
  Appends claim for AppEngine API
  """
  @doc since: "0.1.0"
  @spec append_appengine_claim(t, binary) :: t
  def append_appengine_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_aea", claim)
  end

  @doc """
  Appends claim for Astarte Channels
  """
  @doc since: "0.1.0"
  @spec append_channels_claim(t, binary) :: t
  def append_channels_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_ch", claim)
  end

  @doc """
  Appends claim for Flow API
  """
  @doc since: "0.1.0"
  @spec append_flow_claim(t, binary) :: t
  def append_flow_claim(%Credentials{} = credentials, claim) when is_binary(claim) do
    append_claim(credentials, "a_f", claim)
  end

  defp append_claim(%Credentials{claims: claims} = credentials, claim_key, claim_value) do
    updated_claims = Map.update(claims, claim_key, [claim_value], &[claim_value | &1])
    %{credentials | claims: updated_claims}
  end

  @doc """
  Sets expiry used to generate expiration time claim.

  The possible expiry values are:
    * `:infinity` - do not add expiration time claim
    * `positive integer` - the amount of time in seconds to be added to the current time
      at JWT generation moment
  """
  @doc since: "0.1.0"
  @spec set_expiry(t, expiry :: :infinity | pos_integer) :: t

  def set_expiry(%Credentials{} = credentials, :infinity) do
    %{credentials | expiry: :infinity}
  end

  def set_expiry(%Credentials{} = credentials, expiry_seconds)
      when is_integer(expiry_seconds) and expiry_seconds > 0 do
    %{credentials | expiry: expiry_seconds}
  end

  @doc """
  Sets issuer claim
  """
  @doc since: "0.1.0"
  @spec set_issuer(t, binary) :: t
  def set_issuer(%Credentials{} = credentials, issuer) when is_binary(issuer) do
    %{credentials | issuer: issuer}
  end

  defp maybe_set_issuer(%Credentials{} = credentials, nil), do: credentials

  defp maybe_set_issuer(%Credentials{} = credentials, issuer) when is_binary(issuer) do
    set_issuer(credentials, issuer)
  end

  @doc """
  Sets subject claim
  """
  @doc since: "0.1.0"
  @spec set_subject(t, binary) :: t
  def set_subject(%Credentials{} = credentials, subject) when is_binary(subject) do
    %{credentials | subject: subject}
  end

  defp maybe_set_subject(%Credentials{} = credentials, nil), do: credentials

  defp maybe_set_subject(%Credentials{} = credentials, subject) when is_binary(subject) do
    set_subject(credentials, subject)
  end

  defp build_token_config(%Credentials{} = credentials) do
    %Credentials{issuer: issuer, subject: subject, expiry: expiry} = credentials

    %{}
    |> add_issuer_claim(issuer)
    |> maybe_add_subject_claim(subject)
    |> maybe_add_expiration_claim(expiry)
    |> add_issued_at_claim()
  end

  defp add_issuer_claim(config, nil) do
    Joken.Config.add_claim(config, "iss", fn ->
      "Astarte Client Elixir v#{Application.spec(:astarte_client, :vsn)}"
    end)
  end

  defp add_issuer_claim(config, issuer) when is_binary(issuer) do
    Joken.Config.add_claim(config, "iss", fn -> issuer end)
  end

  defp maybe_add_subject_claim(config, nil), do: config

  defp maybe_add_subject_claim(config, subject) when is_binary(subject) do
    Joken.Config.add_claim(config, "sub", fn -> subject end)
  end

  defp maybe_add_expiration_claim(config, :infinity), do: config

  defp maybe_add_expiration_claim(config, expiry) when is_integer(expiry) and expiry > 0 do
    Joken.Config.add_claim(config, "exp", fn -> Joken.current_time() + expiry end)
  end

  defp maybe_add_expiration_claim(config, _) do
    Joken.Config.add_claim(config, "exp", fn -> Joken.current_time() + @default_expiry end)
  end

  defp add_issued_at_claim(config) do
    Joken.Config.add_claim(config, "iat", fn -> Joken.current_time() end)
  end

  @doc """
  Generates JWT with given private key
  """
  @doc since: "0.1.0"
  @spec to_jwt(t, binary) :: {:ok, binary} | {:error, any}
  def to_jwt(%Credentials{} = credentials, private_key_pem) do
    %Credentials{claims: astarte_claims} = credentials
    token_config = build_token_config(credentials)

    with {:ok, algo} <- signing_algorithm(private_key_pem),
         signer = Joken.Signer.create(algo, %{"pem" => private_key_pem}),
         {:ok, token, _claims} <- Joken.generate_and_sign(token_config, astarte_claims, signer) do
      {:ok, token}
    end
  end

  defp signing_algorithm(private_key) do
    case X509.PrivateKey.from_pem(private_key) do
      {:ok, key} when Record.is_record(key, :ECPrivateKey) ->
        case ec_private_key(key, :parameters) do
          # secp256r1 curve
          {:namedCurve, {1, 2, 840, 10_045, 3, 1, 7}} ->
            {:ok, "ES256"}

          # secp384r1 curve
          {:namedCurve, {1, 3, 132, 0, 34}} ->
            {:ok, "ES384"}

          _ ->
            {:error, :unsupported_private_key}
        end

      {:ok, key} when Record.is_record(key, :RSAPrivateKey) ->
        {:ok, "RS256"}

      _ ->
        {:error, :unsupported_private_key}
    end
  end
end
