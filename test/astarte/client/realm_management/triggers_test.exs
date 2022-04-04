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

defmodule Astarte.Client.RealmManagement.TriggersTest do
  use ExUnit.Case
  doctest Astarte.Client.RealmManagement.Triggers

  alias Astarte.Client.{APIError, RealmManagement}
  alias Astarte.Client.RealmManagement.Triggers

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"
  @trigger_name "device-connection"
  @trigger_data %{
    "action" => %{
      "http_method" => "post",
      "http_static_headers" => %{},
      "http_url" => "http://base-url:4000/tenants/#{@realm_name}/triggers"
    },
    "name" => "device-connection",
    "simple_triggers" => [
      %{"on" => "device_connected", "type" => "device_trigger"}
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
        assert url == build_trigger_url()

        Tesla.Mock.json(
          %{"data" => []},
          status: 200
        )
      end)

      Triggers.list(client)
    end

    test "returns list of triggers", %{client: client} do
      triggers_data = %{"data" => [@trigger_name]}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(triggers_data, status: 200)
      end)

      assert {:ok, triggers_data} == Triggers.list(client)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Triggers.list(client)
    end
  end

  describe "get/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_trigger_url(@trigger_name)

        Tesla.Mock.json(
          %{"data" => @trigger_data},
          status: 200
        )
      end)

      Triggers.get(client, @trigger_name)
    end

    test "returns trigger configuration for existing trigger", %{client: client} do
      trigger_data = %{"data" => @trigger_data}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(trigger_data, status: 200)
      end)

      assert {:ok, trigger_data} == Triggers.get(client, @trigger_name)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Trigger not found"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Triggers.get(client, @trigger_name)
    end
  end

  describe "create/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :post
        assert url == build_trigger_url()

        Tesla.Mock.json(
          @trigger_data,
          status: 201
        )
      end)

      Triggers.create(client, @trigger_data)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(@trigger_data, status: 201)
      end)

      assert :ok == Triggers.create(client, @trigger_data)
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Trigger already exists"}}
      error_status = 409

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Triggers.create(client, @trigger_data)
    end
  end

  describe "delete/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :delete
        assert url == build_trigger_url(@trigger_name)

        %Tesla.Env{status: 204}
      end)

      Triggers.delete(client, @trigger_name)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 204} end)

      assert :ok == Triggers.delete(client, @trigger_name)
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Trigger not found"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Triggers.delete(client, @trigger_name)
    end
  end

  defp build_trigger_url(trigger_name \\ "") do
    Path.join([@base_url, "realmmanagement", "v1", @realm_name, "triggers", trigger_name])
  end
end
