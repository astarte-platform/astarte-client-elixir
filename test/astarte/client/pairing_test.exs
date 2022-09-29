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

defmodule Astarte.Client.PairingTest do
  use ExUnit.Case, async: true

  alias Astarte.Client.Pairing
  alias Astarte.Client.Pairing.Agent

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"
  @valid_private_key X509.PrivateKey.new_ec(:secp256r1) |> X509.PrivateKey.to_pem()
  @invalid_private_key "notaprivatekey"
  @signer Joken.Signer.create("ES256", %{"pem" => @valid_private_key})

  describe "new/2" do
    test "with jwt creates client" do
      assert {:ok, %Pairing{} = _client} = Pairing.new(@base_url, @realm_name, jwt: @jwt)
    end

    test "with valid private_key creates client" do
      assert {:ok, %Pairing{} = _client} =
               Pairing.new(@base_url, @realm_name, private_key: @valid_private_key)
    end

    test "with invalid private_key returns error" do
      assert {:error, :unsupported_private_key} =
               Pairing.new(@base_url, @realm_name, private_key: @invalid_private_key)
    end

    test "without jwt and private_key returns error" do
      assert {:error, :missing_jwt_and_private_key} = Pairing.new(@base_url, @realm_name, [])
    end

    test "without jwt_opts generates JWT with issuer and expiration time claims" do
      assert {:ok, %Pairing{} = client} =
               Pairing.new(@base_url, @realm_name, private_key: @valid_private_key)

      Tesla.Mock.mock(fn env ->
        assert "Bearer: " <> jwt = Tesla.get_header(env, "Authorization")
        assert {:ok, claims} = Joken.verify(jwt, @signer)

        assert %{
                 "a_pa" => _,
                 "iss" => _,
                 "exp" => _
               } = claims

        %Tesla.Env{status: 201}
      end)

      assert {:ok, _} = Agent.register(client, %{})
    end

    test "with jwt_opts generates JWT with requested claims" do
      issuer = "foo"
      subject = "bar"
      expiry = :infinity

      assert {:ok, %Pairing{} = client} =
               Pairing.new(@base_url, @realm_name,
                 private_key: @valid_private_key,
                 jwt_opts: [issuer: issuer, subject: subject, expiry: expiry]
               )

      Tesla.Mock.mock(fn env ->
        assert "Bearer: " <> jwt = Tesla.get_header(env, "Authorization")
        assert {:ok, claims} = Joken.verify(jwt, @signer)

        assert %{
                 "a_pa" => _,
                 "iss" => ^issuer,
                 "sub" => ^subject
               } = claims

        refute is_map_key(claims, "exp")

        %Tesla.Env{status: 201}
      end)

      assert {:ok, _} = Agent.register(client, %{})
    end
  end
end
