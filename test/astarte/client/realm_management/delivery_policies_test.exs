#
# This file is part of Astarte.
#
# Copyright 2024 SECO Mind
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

defmodule Astarte.Client.RealmManagement.DeliveryPoliciesTest do
  use ExUnit.Case
  doctest Astarte.Client.RealmManagement.DeliveryPolicies

  alias Astarte.Client.{APIError, RealmManagement}
  alias Astarte.Client.RealmManagement.DeliveryPolicies

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"
  @policy_name "simple_policy"
  @delivery_policy_data %{
    "name" => "simple_policy",
    "maximum_capacity" => 100,
    "error_handlers" => [
      %{
        "on" => "any_error",
        "strategy" => "discard"
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
        assert url == build_delivery_policy_url()

        Tesla.Mock.json(
          %{"data" => []},
          status: 200
        )
      end)

      DeliveryPolicies.list(client)
    end

    test "returns list of delivery policies", %{client: client} do
      delivery_policy_data = %{"data" => [@policy_name]}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(delivery_policy_data, status: 200)
      end)

      assert {:ok, delivery_policy_data} == DeliveryPolicies.list(client)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               DeliveryPolicies.list(client)
    end
  end

  describe "get/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_delivery_policy_url(@policy_name)

        Tesla.Mock.json(
          %{"data" => @delivery_policy_data},
          status: 200
        )
      end)

      DeliveryPolicies.get(client, @policy_name)
    end

    test "returns delivery policy configuration for existing delivery policy", %{client: client} do
      delivery_policy_data = %{"data" => @delivery_policy_data}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(delivery_policy_data, status: 200)
      end)

      assert {:ok, delivery_policy_data} == DeliveryPolicies.get(client, @policy_name)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Trigger policy not found"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               DeliveryPolicies.get(client, @policy_name)
    end
  end

  describe "create/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :post
        assert url == build_delivery_policy_url()

        Tesla.Mock.json(
          @delivery_policy_data,
          status: 201
        )
      end)

      DeliveryPolicies.create(client, @delivery_policy_data)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(@delivery_policy_data, status: 201)
      end)

      assert :ok == DeliveryPolicies.create(client, @delivery_policy_data)
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Policy already exists"}}
      error_status = 409

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               DeliveryPolicies.create(client, @delivery_policy_data)
    end
  end

  describe "delete/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :delete
        assert url == build_delivery_policy_url(@policy_name)

        %Tesla.Env{status: 204}
      end)

      DeliveryPolicies.delete(client, @policy_name)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 204} end)

      assert :ok == DeliveryPolicies.delete(client, @policy_name)
    end

    test "returns APIError on 404 error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Trigger policy not found"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               DeliveryPolicies.delete(client, @policy_name)
    end

    test "returns APIError on 409 error", %{client: client} do
      error_data = %{
        "errors" => %{
          "detail" => "Cannot delete policy as it is being currently used by triggers"
        }
      }

      error_status = 409

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               DeliveryPolicies.delete(client, @policy_name)
    end
  end

  defp build_delivery_policy_url(policy_name \\ "") do
    Path.join([@base_url, "realmmanagement", "v1", @realm_name, "policies", policy_name])
  end
end
