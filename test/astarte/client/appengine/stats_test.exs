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

defmodule Astarte.Client.AppEngine.StatsTest do
  use ExUnit.Case
  doctest Astarte.Client.AppEngine.Stats

  alias Astarte.Client.{APIError, AppEngine}
  alias Astarte.Client.AppEngine.Stats

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"

  setup do
    {:ok, %AppEngine{} = client} = AppEngine.new(@base_url, @realm_name, jwt: @jwt)

    {:ok, client: client}
  end

  describe "get_devices_stats/1" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_stats_devices_url()

        Tesla.Mock.json(
          %{"data" => %{"connected_devices" => 1, "total_devices" => 2}},
          status: 200
        )
      end)

      Stats.get_devices_stats(client)
    end

    test "returns stats data for existing realm", %{client: client} do
      stats_data = %{"data" => %{"connected_devices" => 1, "total_devices" => 2}}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(stats_data, status: 200)
      end)

      assert {:ok, stats_data} == Stats.get_devices_stats(client)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Stats.get_devices_stats(client)
    end
  end

  defp build_stats_devices_url do
    Path.join([@base_url, "appengine", "v1", @realm_name, "stats", "devices"])
  end
end
