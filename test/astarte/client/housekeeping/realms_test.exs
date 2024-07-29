#
# This file is part of Astarte.
#
# Copyright 2022-2024 SECO Mind
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

defmodule Astarte.Client.Housekeeping.RealmsTest do
  use ExUnit.Case
  doctest Astarte.Client.Housekeeping.Realms

  alias Astarte.Client.APIError
  alias Astarte.Client.Housekeeping
  alias Astarte.Client.Housekeeping.Realms

  @base_url "https://base-url.com"
  @jwt "notarealjwt"
  @realm_name "myrealm"
  @realm_public_key X509.PrivateKey.new_ec(:secp256r1)
                    |> X509.PublicKey.derive()
                    |> X509.PublicKey.to_pem()

  setup do
    {:ok, %Housekeeping{} = client} = Housekeeping.new(@base_url, jwt: @jwt)

    {:ok, client: client}
  end

  describe "list/1" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_realm_url()

        Tesla.Mock.json(
          %{"data" => []},
          status: 200
        )
      end)

      Realms.list(client)
    end

    test "returns list of existing realms", %{client: client} do
      Tesla.Mock.mock(fn %{} ->
        Tesla.Mock.json(
          %{"data" => ["realm1", "realm2"]},
          status: 200
        )
      end)

      assert {:ok, %{"data" => ["realm1", "realm2"]}} = Realms.list(client)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn %{} ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Realms.list(client)
    end
  end

  describe "get/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_realm_url("myrealm")

        Tesla.Mock.json(
          realm_response(),
          status: 200
        )
      end)

      Realms.get(client, "myrealm")
    end

    test "returns realm configuration", %{client: client} do
      Tesla.Mock.mock(fn %{} ->
        Tesla.Mock.json(
          realm_response(realm_name: "myrealm"),
          status: 200
        )
      end)

      assert {:ok,
              %{
                "data" => %{
                  "datastream_maximum_storage_retention" => nil,
                  "device_registration_limit" => nil,
                  "jwt_public_key_pem" => "-----BEGIN PUBLIC KEY-----" <> _,
                  "realm_name" => "myrealm",
                  "replication_class" => "SimpleStrategy",
                  "replication_factor" => 1
                }
              }} = Realms.get(client, "myrealm")
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn %{} ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Realms.get(client, "myrealm")
    end
  end

  describe "create/4" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :post
        assert url == build_realm_url()

        Tesla.Mock.json(
          realm_response(),
          status: 201
        )
      end)

      Realms.create(client, @realm_name, @realm_public_key, replication_factor: 1)
    end

    test "specifies query parameters", %{client: client} do
      opts = [query: [async_operation: false]]

      Tesla.Mock.mock(fn %{query: query} ->
        assert query == [async_operation: false]

        Tesla.Mock.json(realm_response(), status: 201)
      end)

      assert :ok =
               Realms.create(
                 client,
                 @realm_name,
                 @realm_public_key,
                 [replication_factor: 1] ++ opts
               )
    end

    test "specifies realm name", %{client: client} do
      realm_name = @realm_name

      Tesla.Mock.mock(fn %{body: body} ->
        assert %{
                 "data" => %{
                   "realm_name" => ^realm_name
                 }
               } = Jason.decode!(body)

        Tesla.Mock.json(realm_response(), status: 201)
      end)

      assert :ok = Realms.create(client, realm_name, @realm_public_key, replication_factor: 1)
    end

    test "specifies public key", %{client: client} do
      realm_public_key = @realm_public_key

      Tesla.Mock.mock(fn %{body: body} ->
        assert %{
                 "data" => %{
                   "jwt_public_key_pem" => ^realm_public_key
                 }
               } = Jason.decode!(body)

        Tesla.Mock.json(realm_response(), status: 201)
      end)

      assert :ok = Realms.create(client, @realm_name, realm_public_key, replication_factor: 1)
    end

    test "specifies integer device registration limit", %{client: client} do
      opts = [device_registration_limit: 1]

      Tesla.Mock.mock(fn %{body: body} ->
        assert %{
                 "data" => %{
                   "device_registration_limit" => 1
                 }
               } = Jason.decode!(body)

        Tesla.Mock.json(realm_response(), status: 201)
      end)

      assert :ok =
               Realms.create(
                 client,
                 @realm_name,
                 @realm_public_key,
                 [replication_factor: 1] ++ opts
               )
    end

    test "specifies nil device registration limit", %{client: client} do
      opts = [device_registration_limit: nil]

      Tesla.Mock.mock(fn %{body: body} ->
        assert %{
                 "data" => %{
                   "device_registration_limit" => nil
                 }
               } = Jason.decode!(body)

        Tesla.Mock.json(realm_response(), status: 201)
      end)

      assert :ok =
               Realms.create(
                 client,
                 @realm_name,
                 @realm_public_key,
                 [replication_factor: 1] ++ opts
               )
    end

    test "specifies nil without a defined device registration limit", %{client: client} do
      Tesla.Mock.mock(fn %{body: body} ->
        assert %{
                 "data" => %{
                   "device_registration_limit" => nil
                 }
               } = Jason.decode!(body)

        Tesla.Mock.json(realm_response(), status: 201)
      end)

      assert :ok = Realms.create(client, @realm_name, @realm_public_key, replication_factor: 1)
    end

    test "specifies replication with simple strategy", %{client: client} do
      opts = [replication_factor: 1]

      Tesla.Mock.mock(fn %{body: body} ->
        assert %{
                 "data" => %{
                   "replication_class" => "SimpleStrategy",
                   "replication_factor" => 1
                 }
               } = Jason.decode!(body)

        Tesla.Mock.json(realm_response(), status: 201)
      end)

      assert :ok = Realms.create(client, @realm_name, @realm_public_key, opts)
    end

    test "specifies replication with network topology strategy", %{client: client} do
      opts = [datacenter_replication_factors: %{"DC1" => 3}]

      Tesla.Mock.mock(fn %{body: body} ->
        assert %{
                 "data" => %{
                   "replication_class" => "NetworkTopologyStrategy",
                   "datacenter_replication_factors" => %{"DC1" => 3}
                 }
               } = Jason.decode!(body)

        Tesla.Mock.json(realm_response(), status: 201)
      end)

      assert :ok = Realms.create(client, @realm_name, @realm_public_key, opts)
    end

    test "returns error if replication is not specified", %{client: client} do
      assert {:error, :missing_replication} =
               Realms.create(client, @realm_name, @realm_public_key, [])
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn %{} ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Realms.create(client, @realm_name, @realm_public_key, replication_factor: 1)
    end
  end

  describe "update/3" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :patch
        assert url == build_realm_url(@realm_name)

        Tesla.Mock.json(
          realm_response(),
          status: 200
        )
      end)

      Realms.update(client, @realm_name, [])
    end

    test "specifies public key", %{client: client} do
      realm_public_key = @realm_public_key

      Tesla.Mock.mock(fn %{body: body} ->
        assert %{
                 "data" => %{
                   "jwt_public_key_pem" => ^realm_public_key
                 }
               } = Jason.decode!(body)

        Tesla.Mock.json(realm_response(), status: 200)
      end)

      assert :ok = Realms.update(client, @realm_name, jwt_public_key_pem: realm_public_key)
    end

    test "specifies integer device registration limit", %{client: client} do
      device_registration_limit = 1

      Tesla.Mock.mock(fn %{body: body} ->
        assert %{
                 "data" => %{
                   "device_registration_limit" => ^device_registration_limit
                 }
               } = Jason.decode!(body)

        Tesla.Mock.json(realm_response(), status: 200)
      end)

      assert :ok =
               Realms.update(client, @realm_name,
                 device_registration_limit: device_registration_limit
               )
    end

    test "specifies nil device registration limit", %{client: client} do
      device_registration_limit = nil

      Tesla.Mock.mock(fn %{body: body} ->
        assert %{
                 "data" => %{
                   "device_registration_limit" => ^device_registration_limit
                 }
               } = Jason.decode!(body)

        Tesla.Mock.json(realm_response(), status: 200)
      end)

      assert :ok =
               Realms.update(client, @realm_name,
                 device_registration_limit: device_registration_limit
               )
    end

    test "does not specify device registration limit if undefined", %{client: client} do
      Tesla.Mock.mock(fn %{body: body} ->
        assert %{"data" => data} = Jason.decode!(body)
        refute Map.has_key?(data, "device_registration_limit")

        Tesla.Mock.json(realm_response(), status: 200)
      end)

      assert :ok = Realms.update(client, @realm_name, [])
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn %{} ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Realms.update(client, @realm_name, [])
    end
  end

  describe "delete/3" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :delete
        assert url == build_realm_url(@realm_name)

        Tesla.Mock.json(
          realm_response(),
          status: 204
        )
      end)

      Realms.delete(client, @realm_name, [])
    end

    test "specifies query parameters", %{client: client} do
      opts = [query: [async_operation: false]]

      Tesla.Mock.mock(fn %{query: query} ->
        assert query == [async_operation: false]

        Tesla.Mock.json(realm_response(), status: 204)
      end)

      assert :ok = Realms.delete(client, @realm_name, opts)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn %{} ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Realms.delete(client, @realm_name, [])
    end
  end

  describe "fetch_replication/1" do
    test "fetches valid replications" do
      assert {:ok,
              %{
                datacenter_replication_factors: %{"europe-west1" => 3, "europe-west2" => 2},
                replication_class: "NetworkTopologyStrategy"
              }} ==
               Realms.fetch_replication(
                 datacenter_replication_factors: %{"europe-west1" => 3, "europe-west2" => 2}
               )

      assert {:ok,
              %{
                replication_factor: 3,
                replication_class: "SimpleStrategy"
              }} == Realms.fetch_replication(replication_factor: 3)
    end

    test "rejects invalid datacenter_replication_factors" do
      assert {:error, :datacenter_replication_factor_invalid_format} ==
               Realms.fetch_replication(datacenter_replication_factors: %{})

      assert {:error, :datacenter_replication_factor_invalid_format} ==
               Realms.fetch_replication(datacenter_replication_factors: 3)
    end

    test "rejects invalid replication_factors" do
      assert {:error, :replication_factor_invalid_format} ==
               Realms.fetch_replication(replication_factor: 0)

      assert {:error, :replication_factor_invalid_format} ==
               Realms.fetch_replication(replication_factor: "2")

      assert {:error, :replication_factor_invalid_format} ==
               Realms.fetch_replication(
                 replication_factor: %{"europe-west1" => 3, "europe-west2" => 2}
               )
    end

    test "rejects opts without replication data" do
      assert {:error, :missing_replication} == Realms.fetch_replication([])
    end
  end

  defp build_realm_url(realm_name \\ "") do
    Path.join([@base_url, "housekeeping", "v1", "realms", realm_name])
  end

  defp realm_response(opts \\ []) do
    replication_data =
      case Keyword.fetch(opts, :datacenter_replication_factors) do
        {:ok, datacenter_replication_factors} ->
          %{
            "replication_class" => "NetworkTopologyStrategy",
            "datacenter_replication_factors" => datacenter_replication_factors
          }

        :error ->
          %{
            "replication_class" => "SimpleStrategy",
            "replication_factor" => opts[:replication_factor] || 1
          }
      end

    %{
      "data" =>
        %{
          "datastream_maximum_storage_retention" => nil,
          "device_registration_limit" => opts[:device_registration_limit],
          "jwt_public_key_pem" => opts[:jwt_public_key_pem] || @realm_public_key,
          "realm_name" => opts[:realm_name] || @realm_name
        }
        |> Map.merge(replication_data)
    }
  end
end
