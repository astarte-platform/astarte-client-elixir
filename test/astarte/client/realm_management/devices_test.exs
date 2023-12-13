#
# This file is part of Astarte.
#
# Copyright 2023 SECO Mind
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

defmodule Astarte.Client.RealmManagement.DevicesTest do
  use ExUnit.Case
  doctest Astarte.Client.RealmManagement.Devices

  alias Astarte.Client.{APIError, RealmManagement}
  alias Astarte.Client.RealmManagement.Devices

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"
  @device_id "YhDfHaJ2Tv2aeGXfkOBTbw"

  setup do
    {:ok, %RealmManagement{} = client} = RealmManagement.new(@base_url, @realm_name, jwt: @jwt)

    {:ok, client: client}
  end

  describe "delete/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :delete
        assert url == build_device_url(@device_id)

        %Tesla.Env{status: 204}
      end)

      Devices.delete(client, @device_id)
    end

    test "returns :ok if response is successful", %{client: client} do
      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 204} end)

      assert :ok == Devices.delete(client, @device_id)
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Device not found"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Devices.delete(client, @device_id)
    end
  end

  defp build_device_url(device_id) when is_binary(device_id) do
    Path.join([
      @base_url,
      "realmmanagement",
      "v1",
      @realm_name,
      "devices",
      device_id
    ])
  end
end
