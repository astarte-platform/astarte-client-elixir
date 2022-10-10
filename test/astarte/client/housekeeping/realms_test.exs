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

defmodule Astarte.Client.Housekeeping.RealmsTest do
  use ExUnit.Case

  alias Astarte.Client.Housekeeping.Realms

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
end
