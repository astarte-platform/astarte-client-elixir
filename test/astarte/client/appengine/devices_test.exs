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

defmodule Astarte.Client.AppEngine.DevicesTest do
  use ExUnit.Case
  doctest Astarte.Client.AppEngine.Devices

  alias Astarte.Client.{APIError, AppEngine}
  alias Astarte.Client.AppEngine.Devices

  @base_url "https://base-url.com"
  @realm_name "realm_name"
  @jwt "notarealjwt"
  @device_id "device_id"

  @sensors_interface "org.astarte-platform.genericsensors.AvailableSensors"
  @sensor_path "/b2c5a6ed-ebe4-4c5c-9d8a-6d2f114fc6e5"
  @sensor_name "randomThermometer"
  @sensor_unit "°C"

  @sensor_data %{
    "name" => @sensor_name,
    "unit" => @sensor_unit
  }
  @sensors_data %{
    "#{@sensor_path}" => @sensor_data
  }

  @sensors_stream_interface "org.astarte-platform.genericsensors.Values"
  @sensor_stream_last_data %{
    "value" => 20.2,
    "timestamp" => "2022-02-01T12:00:02.837Z"
  }
  @sensor_stream_data [
    %{
      "value" => 20.1,
      "timestamp" => "2022-02-01T12:00:00.827Z"
    },
    %{
      "value" => 20.2,
      "timestamp" => "2022-02-01T12:00:01.827Z"
    },
    @sensor_stream_last_data
  ]
  @sensors_steam_data %{
    "#{@sensor_path}" => @sensor_stream_data
  }

  setup do
    {:ok, %AppEngine{} = client} = AppEngine.new(@base_url, @realm_name, jwt: @jwt)

    {:ok, client: client}
  end

  describe "get_device_status/2" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_device_url(@device_id)

        Tesla.Mock.json(
          %{"data" => "device_overview_data"},
          status: 200
        )
      end)

      Devices.get_device_status(client, @device_id)
    end

    test "returns overview data for existing device", %{client: client} do
      overview_data = %{"data" => "device_overview_data"}

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(overview_data, status: 200)
      end)

      assert {:ok, overview_data} == Devices.get_device_status(client, @device_id)
    end

    test "retuns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Device not found"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Devices.get_device_status(client, @device_id)
    end
  end

  describe "get_properties_data/3" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_interface_url(@device_id, @sensors_interface)

        Tesla.Mock.json(
          %{"data" => @sensors_data},
          status: 200
        )
      end)

      Devices.get_properties_data(client, @device_id, @sensors_interface)
    end

    test "returns data from successful response", %{client: client} do
      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(
          %{"data" => @sensors_data},
          status: 200
        )
      end)

      assert {:ok, body} = Devices.get_properties_data(client, @device_id, @sensors_interface)
      assert body["data"] == @sensors_data
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Devices.get_properties_data(client, @device_id, @sensors_interface)
    end
  end

  describe "get_properties_data/4" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_interface_url(@device_id, @sensors_interface, path: @sensor_path)

        Tesla.Mock.json(
          %{"data" => @sensor_data},
          status: 200
        )
      end)

      Devices.get_properties_data(client, @device_id, @sensors_interface, path: @sensor_path)
    end

    test "returns data from successful response", %{client: client} do
      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(
          %{"data" => @sensor_data},
          status: 200
        )
      end)

      assert {:ok, body} =
               Devices.get_properties_data(client, @device_id, @sensors_interface,
                 path: @sensor_path
               )

      assert body["data"] == @sensor_data
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Forbidden"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Devices.get_properties_data(client, @device_id, @sensors_interface,
                 path: @sensor_path
               )
    end
  end

  describe "set_property/5" do
    test "makes a request to expected url using expected method", %{client: client} do
      path = Path.join([@sensor_path, "name"])
      new_name = "randomThermometer 2"

      Tesla.Mock.mock(fn %{method: method, url: url, body: body} ->
        assert method == :put
        assert url == build_interface_url(@device_id, @sensors_interface, path: path)

        Tesla.Mock.json(
          body,
          status: 200
        )
      end)

      Devices.set_property(client, @device_id, @sensors_interface, path, new_name)
    end

    test "returns :ok if response is successful", %{client: client} do
      path = Path.join([@sensor_path, "name"])
      new_name = "randomThermometer 2"

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(
          %{"data" => new_name},
          status: 200
        )
      end)

      assert :ok == Devices.set_property(client, @device_id, @sensors_interface, path, new_name)
    end

    test "returns APIError on error", %{client: client} do
      path = Path.join([@sensor_path, "name"])
      new_name = 1_000_000

      error_data = %{
        "errors" => %{"detail" => "Unexpected value type", "expected_type" => "string"}
      }

      error_status = 422

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Devices.set_property(client, @device_id, @sensors_interface, path, new_name)
    end
  end

  describe "unset_property/4" do
    test "makes a request to expected url using expected method", %{client: client} do
      path = Path.join([@sensor_path, "name"])

      Tesla.Mock.mock(fn %{method: method, url: url, body: body} ->
        assert method == :delete
        assert url == build_interface_url(@device_id, @sensors_interface, path: path)

        Tesla.Mock.json(
          body,
          status: 200
        )
      end)

      Devices.unset_property(client, @device_id, @sensors_interface, path)
    end

    test "returns :ok if response is successful", %{client: client} do
      path = Path.join([@sensor_path, "name"])

      Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 204} end)

      assert :ok == Devices.unset_property(client, @device_id, @sensors_interface, path)
    end

    test "returns APIError on error", %{client: client} do
      path = Path.join([@sensor_path, "name"])

      error_data = %{"errors" => %{"detail" => "Interface not found in device introspection"}}
      error_status = 404

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Devices.unset_property(client, @device_id, @sensors_interface, path)
    end
  end

  describe "get_datastream_data/3" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get
        assert url == build_interface_url(@device_id, @sensors_stream_interface)

        Tesla.Mock.json(
          %{"data" => @sensors_steam_data},
          status: 200
        )
      end)

      Devices.get_datastream_data(client, @device_id, @sensors_stream_interface)
    end

    test "returns data from successful response", %{client: client} do
      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(
          %{"data" => @sensors_steam_data},
          status: 200
        )
      end)

      assert {:ok, body} =
               Devices.get_datastream_data(client, @device_id, @sensors_stream_interface)

      assert body["data"] == @sensors_steam_data
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Interface not found in device introspection"}}
      error_status = 403

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Devices.get_datastream_data(
                 client,
                 @device_id,
                 "org.astarte-platform.unexistingInterface"
               )
    end
  end

  describe "get_datastream_data/4" do
    test "makes a request to expected url using expected method", %{client: client} do
      Tesla.Mock.mock(fn %{method: method, url: url} ->
        assert method == :get

        assert url ==
                 build_interface_url(@device_id, @sensors_stream_interface, path: @sensor_path)

        Tesla.Mock.json(
          %{"data" => @sensor_stream_data},
          status: 200
        )
      end)

      Devices.get_datastream_data(client, @device_id, @sensors_stream_interface,
        path: @sensor_path
      )
    end

    test "makes a request to expected url using expected method and passing query parameters without mapping path",
         %{
           client: client
         } do
      query_params = [limit: 1]

      Tesla.Mock.mock(fn %{method: method, url: url, query: query} ->
        assert method == :get

        assert url ==
                 build_interface_url(@device_id, @sensors_stream_interface, query: query_params)

        assert query_params == query

        Tesla.Mock.json(
          %{
            "data" => %{
              @sensor_path => @sensor_stream_last_data
            }
          },
          status: 200
        )
      end)

      Devices.get_datastream_data(client, @device_id, @sensors_stream_interface,
        query: query_params
      )
    end

    test "makes a request to expected url using expected method and passing query parameters with mapping path",
         %{
           client: client
         } do
      query_params = [limit: 1]

      Tesla.Mock.mock(fn %{method: method, url: url, query: query} ->
        assert method == :get

        assert url ==
                 build_interface_url(@device_id, @sensors_stream_interface,
                   path: @sensor_path,
                   query: query_params
                 )

        assert query_params == query

        Tesla.Mock.json(
          %{"data" => @sensor_stream_last_data},
          status: 200
        )
      end)

      Devices.get_datastream_data(client, @device_id, @sensors_stream_interface,
        path: @sensor_path,
        query: query_params
      )
    end

    test "returns data from successful response", %{client: client} do
      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(
          %{"data" => @sensor_stream_data},
          status: 200
        )
      end)

      assert {:ok, body} =
               Devices.get_datastream_data(client, @device_id, @sensors_stream_interface,
                 path: @sensor_path
               )

      assert body["data"] == @sensor_stream_data
    end

    test "returns APIError on error", %{client: client} do
      error_data = %{"errors" => %{"detail" => "Endpoint not found"}}
      error_status = 400

      Tesla.Mock.mock(fn _ ->
        Tesla.Mock.json(error_data, status: error_status)
      end)

      assert {:error, %APIError{response: error_data, status: error_status}} ==
               Devices.get_datastream_data(
                 client,
                 @device_id,
                 @sensors_stream_interface,
                 path: "/unexistingEndpoint"
               )
    end
  end

  describe "send_datastream/5" do
    test "makes a request to expected url using expected method", %{client: client} do
      data = %{
        "value" => 20.3,
        "timestamp" => "2022-02-01T12:00:03.837Z"
      }

      Tesla.Mock.mock(fn %{method: method, url: url, body: body} ->
        assert method == :post
        assert url == build_interface_url(@device_id, @sensors_interface, path: @sensor_path)

        Tesla.Mock.json(
          body,
          status: 200
        )
      end)

      Devices.send_datastream(client, @device_id, @sensors_interface, @sensor_path, data)
    end
  end

  defp build_device_url(device_id) do
    Path.join([@base_url, "appengine", "v1", @realm_name, "devices", device_id])
  end

  defp build_interface_url(device_id, interface, opts \\ []) do
    path = Keyword.get(opts, :path, "")

    Path.join([
      build_device_url(device_id),
      "interfaces",
      interface
    ]) <> path
  end
end
