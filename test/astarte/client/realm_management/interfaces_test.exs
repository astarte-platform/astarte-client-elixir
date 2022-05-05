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

defmodule Astarte.Client.RealmManagement.InterfacesTest do
  use ExUnit.Case
  doctest Astarte.Client.RealmManagement.Interfaces

  alias Astarte.Client.{APIError, RealmManagement}
  alias Astarte.Client.RealmManagement.Interfaces

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"
  @interface_name "org.astarteplatform.Values"
  @interface_major_version 0
  @interface_major_versions [0, 1]
  @interface_data %{
    "interface_name" => "org.astarteplatform.Values",
    "version_major" => 0,
    "version_minor" => 1,
    "type" => "datastream",
    "ownership" => "device",
    "mappings" => [
      %{
        "endpoint" => "/realValue",
        "type" => "double",
        "explicit_timestamp" => true
      }
    ]
  }

  setup do
    {:ok, %RealmManagement{} = client} = RealmManagement.new(@base_url, @realm_name, jwt: @jwt)

    {:ok, client: client}
  end

  describe "list/1" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_interface_url()

        Tesla.Mock.json(
          %{"data" => []},
          status: 200
        )
      end)

      Interfaces.list(client)
    end

    test "returns list of all installed interface names", %{client: client} do
      interfaces_data = %{"data" => [@interface_name]}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(interfaces_data, status: 200)
      end)

      assert {:ok, interfaces_data} == Interfaces.list(client)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Interfaces.list(client)
    end
  end

  describe "list_major_versions/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_interface_url(@interface_name)

        Tesla.Mock.json(
          %{"data" => @interface_major_versions},
          status: 200
        )
      end)

      Interfaces.list_major_versions(client, @interface_name)
    end

    test "returns list of major versions for existing interface", %{client: client} do
      major_versions_data = %{"data" => @interface_major_versions}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(major_versions_data, status: 200)
      end)

      assert {:ok, major_versions_data} == Interfaces.list_major_versions(client, @interface_name)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Interface not found"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Interfaces.list_major_versions(client, @interface_name)
    end
  end

  describe "get/3" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_interface_url(@interface_name, @interface_major_version)

        Tesla.Mock.json(
          %{"data" => @interface_data},
          status: 200
        )
      end)

      Interfaces.get(client, @interface_name, @interface_major_version)
    end

    test "returns data from successful response", %{client: client} do
      interface_data = %{"data" => @interface_data}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(interface_data, status: 200)
      end)

      assert {:ok, interface_data} ==
               Interfaces.get(client, @interface_name, @interface_major_version)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Interface not found"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Interfaces.get(client, @interface_name, @interface_major_version)
    end
  end

  describe "create/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :post
        assert url == build_interface_url()

        %Tesla.Env{status: 201}
      end)

      Interfaces.create(client, @interface_data)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 201} end)

      assert :ok == Interfaces.create(client, @interface_data)
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Interface already exists"}}
      error_status = 409

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Interfaces.create(client, @interface_data)
    end
  end

  describe "update/5" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :put
        assert url == build_interface_url(@interface_name, 0)

        %Tesla.Env{status: 204}
      end)

      Interfaces.update(client, @interface_name, 0, @interface_data)
    end

    test "makes a request that includes expected query params", %{client: client} do
      query_params = [param1: 1, param2: 2]

      Tesla.Mock.mock(fn %{query: query} ->
        assert query == query_params

        %Tesla.Env{status: 204}
      end)

      Interfaces.update(client, @interface_name, 0, @interface_data, query: query_params)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 204} end)

      assert :ok == Interfaces.update(client, @interface_name, 0, @interface_data)
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Interface minor version was not increased"}}
      error_status = 409

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Interfaces.update(client, @interface_name, 0, @interface_data)
    end
  end

  describe "delete/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :delete
        assert url == build_interface_url(@interface_name, 0)

        %Tesla.Env{status: 204}
      end)

      Interfaces.delete(client, @interface_name, 0)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 204} end)

      assert :ok == Interfaces.delete(client, @interface_name, 0)
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Interface major not found"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Interfaces.delete(client, @interface_name, 0)
    end
  end

  defp build_interface_url(interface_name \\ "") do
    Path.join([
      @base_url,
      "realmmanagement",
      "v1",
      @realm_name,
      "interfaces",
      interface_name
    ])
  end

  defp build_interface_url(interface_name, major_version) when is_integer(major_version) do
    Path.join([
      build_interface_url(interface_name),
      to_string(major_version)
    ])
  end
end
