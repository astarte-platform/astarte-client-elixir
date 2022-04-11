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

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"
  @valid_private_key X509.PrivateKey.new_ec(:secp256r1) |> X509.PrivateKey.to_pem()
  @invalid_private_key "notaprivatekey"

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
  end
end
