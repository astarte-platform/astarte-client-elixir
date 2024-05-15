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

defmodule Astarte.Client.RealmManagement.VersionTest do
  use ExUnit.Case
  doctest Astarte.Client.RealmManagement.Version

  alias Astarte.Client.{APIError, RealmManagement}
  alias Astarte.Client.RealmManagement.Version

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"
  @version_data "1.1.1"

  setup do
    {:ok, %RealmManagement{} = client} = RealmManagement.new(@base_url, @realm_name, jwt: @jwt)

    {:ok, client: client}
  end

  describe "get/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_rm_api_version_url()

        Tesla.Mock.json(
          %{"data" => @version_data},
          status: 200
        )
      end)

      Version.get(client)
    end

    test "returns realm management api version", %{client: client} do
      version_data = %{"data" => @version_data}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(version_data, status: 200)
      end)

      assert {:ok, version_data} == Version.get(client)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Version.get(client)
    end
  end

  defp build_rm_api_version_url do
    Path.join([@base_url, "realmmanagement", "v1", @realm_name, "version"])
  end
end
