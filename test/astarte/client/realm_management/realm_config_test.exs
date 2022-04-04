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

defmodule Astarte.Client.RealmManagement.RealmConfigTest do
  use ExUnit.Case
  doctest Astarte.Client.RealmManagement.RealmConfig

  alias Astarte.Client.{APIError, RealmManagement}
  alias Astarte.Client.RealmManagement.RealmConfig

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"
  @auth_config_data %{
    "jwt_public_key_pem" =>
      "-----BEGIN PUBLIC KEY-----\nMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEgG/bGSUMcYhfRXRn6MMhtypE9t3z\nELb1jSlnAIWH0+419sMmJimey7KFPKy3oJYncfxvEfME/VoNHOXnLPV+Kg==\n-----END PUBLIC KEY-----\n"
  }

  setup do
    {:ok, %RealmManagement{} = client} = RealmManagement.new(@base_url, @realm_name, jwt: @jwt)

    {:ok, client: client}
  end

  describe "get_auth_config/1" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_auth_config_url()

        Tesla.Mock.json(
          %{"data" => @auth_config_data},
          status: 200
        )
      end)

      RealmConfig.get_auth_config(client)
    end

    test "returns auth config", %{client: client} do
      auth_config_data = %{"data" => @auth_config_data}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(auth_config_data, status: 200)
      end)

      assert {:ok, auth_config_data} == RealmConfig.get_auth_config(client)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               RealmConfig.get_auth_config(client)
    end
  end

  describe "set_auth_config/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :put
        assert url == build_auth_config_url()

        Tesla.Mock.mock(fn _ ->
          %Tesla.Env{status: 204}
        end)
      end)

      RealmConfig.set_auth_config(client, @auth_config_data)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ ->
        %Tesla.Env{status: 204}
      end)

      assert :ok == RealmConfig.set_auth_config(client, @auth_config_data)
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               RealmConfig.set_auth_config(client, @auth_config_data)
    end
  end

  defp build_auth_config_url() do
    Path.join([@base_url, "realmmanagement", "v1", @realm_name, "config", "auth"])
  end
end
