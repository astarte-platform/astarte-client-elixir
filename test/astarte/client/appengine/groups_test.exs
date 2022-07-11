#
# This file is part of Astarte.
#
# Copyright 2021,2022 SECO Mind
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

defmodule Astarte.Client.AppEngine.GroupsTest do
  use ExUnit.Case
  doctest Astarte.Client.AppEngine.Groups

  alias Astarte.Client.{APIError, AppEngine}
  alias Astarte.Client.AppEngine.Groups

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"
  @group_name "group_name"
  @group_data %{"group_name" => @group_name}
  @device_id "device_id"

  setup do
    {:ok, %AppEngine{} = client} = AppEngine.new(@base_url, @realm_name, jwt: @jwt)

    {:ok, client: client}
  end

  describe "list/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_group_url()

        Tesla.Mock.json(%{"data" => []}, status: 200)
      end)

      Groups.list(client)
    end

    test "returns groups list", %{client: client} do
      groups_data = %{"data" => []}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(groups_data, status: 200)
      end)

      assert {:ok, groups_data} == Groups.list(client)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Groups.list(client)
    end
  end

  describe "create/3" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :post
        assert url == build_group_url()

        %Tesla.Env{status: 201}
      end)

      Groups.create(client, @group_name, [@device_id])
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 201} end)

      assert :ok == Groups.create(client, @group_name, [@device_id])
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"devices" => ["should have at least 1 item(s)"]}}
      error_status = 422

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Groups.create(client, @group_name, [])
    end
  end

  describe "get/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_group_url(@group_name)

        Tesla.Mock.json(
          %{"data" => @group_data},
          status: 200
        )
      end)

      Groups.get(client, @group_name)
    end

    test "returns data from successful response", %{client: client} do
      group_data = %{"data" => @group_data}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(group_data, status: 200)
      end)

      assert {:ok, group_data} == Groups.get(client, @group_name)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Group not found"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Groups.get(client, "unexisting-group-name")
    end
  end

  describe "get_devices/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_group_devices_url(@group_name)

        Tesla.Mock.json(
          %{"data" => []},
          status: 200
        )
      end)

      Groups.get_devices(client, @group_name)
    end

    test "passes query parameters", %{client: client} do
      query_opts = [details: true]

      Tesla.Mock.mock(fn %{query: query} ->
        assert query == query_opts

        Tesla.Mock.json(
          %{"data" => []},
          status: 200
        )
      end)

      Groups.get_devices(client, @group_name, query: query_opts)
    end

    test "returns list of existing devices for group", %{client: client} do
      Tesla.Mock.mock(fn %{query: query} ->
        {from_token, _} = Integer.parse(Keyword.get(query, :from_token, "0"))

        if from_token >= 3 do
          Tesla.Mock.json(
            %{
              "data" => [random_device_id(), random_device_id()],
              "links" => %{
                "self" =>
                  "/v1/#{@realm_name}/groups/#{@group_name}/devices?from_token=#{from_token}"
              }
            },
            status: 200
          )
        else
          Tesla.Mock.json(
            %{
              "data" => [random_device_id(), random_device_id()],
              "links" => %{
                "self" =>
                  "/v1/#{@realm_name}/groups/#{@group_name}/devices?from_token=#{from_token}",
                "next" =>
                  "/v1/#{@realm_name}/groups/#{@group_name}/devices?from_token=#{from_token + 1}"
              }
            },
            status: 200
          )
        end
      end)

      assert {:ok, %{"data" => devices}} = Groups.get_devices(client, @group_name)
      assert length(devices) == 8
    end

    test "returns empty list", %{client: client} do
      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(
          %{
            "data" => [],
            "links" => %{
              "self" => "/v1/#{@realm_name}/groups/#{@group_name}/devices"
            }
          },
          status: 200
        )
      end)

      assert {:ok, %{"data" => []}} == Groups.get_devices(client, @group_name)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn %{query: query} ->
        {from_token, _} = Integer.parse(Keyword.get(query, :from_token, "0"))

        if from_token >= 3 do
          Tesla.Mock.json(error_data, status: error_status)
        else
          Tesla.Mock.json(
            %{
              "data" => [random_device_id(), random_device_id()],
              "links" => %{
                "self" =>
                  "/v1/#{@realm_name}/groups/#{@group_name}/devices?from_token=#{from_token}",
                "next" =>
                  "/v1/#{@realm_name}/groups/#{@group_name}/devices?from_token=#{from_token + 1}"
              }
            },
            status: 200
          )
        end
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Groups.get_devices(client, @group_name)
    end
  end

  describe "add_device/3" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :post
        assert url == build_group_devices_url(@group_name)

        %Tesla.Env{status: 201}
      end)

      Groups.add_device(client, @group_name, @device_id)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 201} end)

      assert :ok == Groups.add_device(client, @group_name, "new_device_id")
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"devices" => ["Device already in group"]}}
      error_status = 409

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Groups.add_device(client, @group_name, @device_id)
    end
  end

  describe "remove_device/3" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :delete
        assert url == build_group_devices_url(@group_name, @device_id)

        %Tesla.Env{status: 204}
      end)

      Groups.remove_device(client, @group_name, @device_id)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 204} end)

      assert :ok == Groups.remove_device(client, @group_name, @device_id)
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Device not found"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Groups.remove_device(client, @group_name, @device_id)
    end
  end

  defp build_group_url(group_name \\ "") do
    Path.join([@base_url, "appengine", "v1", @realm_name, "groups", group_name])
  end

  defp build_group_devices_url(group_name, device_id \\ "") do
    Path.join([
      build_group_url(group_name),
      "devices",
      device_id
    ])
  end

  defp random_device_id do
    <<u0::48, _::4, u1::12, _::2, u2::62>> = :crypto.strong_rand_bytes(16)

    <<u0::48, 4::4, u1::12, 2::2, u2::62>>
    |> Base.url_encode64(padding: false)
  end
end
