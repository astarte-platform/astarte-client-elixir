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

defmodule Astarte.Client.Pairing.AgentTest do
  use ExUnit.Case, async: true

  alias Astarte.Client.{APIError, Pairing}
  alias Astarte.Client.Pairing.Agent

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"
  @registration_data %{"hw_id" => "hardware_id"}
  @device_id "device_id"

  setup do
    {:ok, %Pairing{} = client} = Pairing.new(@base_url, @realm_name, jwt: @jwt)

    {:ok, client: client}
  end

  describe "register/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :post
        assert url == build_agent_device_url()

        Tesla.Mock.json(
          %{"data" => %{"credentials_secret" => "credentials_secret_data"}},
          status: 201
        )
      end)

      Agent.register(client, @registration_data)
    end

    test "returns data with credentials secret for valid request", %{client: client} do
      data = %{"data" => %{"credentials_secret" => "credentials_secret_data"}}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(data, status: 201)
      end)

      assert {:ok, data} == Agent.register(client, @registration_data)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"hw_id" => "can't be blank"}}
      error_status = 422

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Agent.register(client, %{})
    end
  end

  describe "unregister/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :delete
        assert url == build_agent_device_url(@device_id)

        %Tesla.Env{status: 204}
      end)

      Agent.unregister(client, @device_id)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 204} end)

      assert :ok == Agent.unregister(client, @device_id)
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Agent.unregister(client, @device_id)
    end
  end

  defp build_agent_device_url(device_id \\ "") do
    Path.join([@base_url, "pairing", "v1", @realm_name, "agent", "devices", device_id])
  end
end
