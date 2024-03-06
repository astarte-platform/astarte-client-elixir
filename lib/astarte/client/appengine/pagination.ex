#
# This file is part of Astarte.
#
# Copyright 2022-2023 SECO Mind
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

defmodule Astarte.Client.AppEngine.Pagination do
  @moduledoc false
  alias Astarte.Client.{APIError, AppEngine}

  def list(%AppEngine{} = client, request_path, opts \\ []) when is_binary(request_path) do
    query = Keyword.get(opts, :query, [])

    list_data =
      Stream.unfold({client, request_path, query}, &list_stream/1)
      |> Enum.to_list()
      |> List.flatten()

    case List.last(list_data) do
      {:error, _} = error -> error
      _ -> {:ok, %{"data" => list_data}}
    end
  end

  defp list_stream(nil), do: nil

  defp list_stream({%AppEngine{} = client, request_path, query} = list_params) do
    with {:ok, tesla_client} <- AppEngine.fetch_tesla_client(client),
         {:ok, %Tesla.Env{status: 200, body: body}} <-
           Tesla.get(tesla_client, request_path, query: query) do
      process_list_response(body, list_params)
    else
      {:ok, %Tesla.Env{status: status, body: body}} ->
        {{:error, %APIError{status: status, response: body}}, nil}

      error ->
        {error, nil}
    end
  end

  defp process_list_response(%{"data" => entity_list} = body, list_params) do
    {entity_list, next_list_params(body, list_params)}
  end

  defp next_list_params(body, {client, request_path, query}) do
    with {:ok, links} <- links(body),
         {:ok, link} <- next_link(links),
         token when not is_nil(token) <- next_token(link) do
      {client, request_path, Keyword.put(query, :from_token, token)}
    else
      _ -> nil
    end
  end

  defp links(%{"links" => links}) when is_map(links), do: {:ok, links}
  defp links(_), do: {:error, :no_links_data}

  defp next_link(%{"next" => next_link}) when is_binary(next_link), do: {:ok, next_link}
  defp next_link(_), do: {:error, :no_next_link}

  defp next_token(link) when is_binary(link) do
    link
    |> URI.parse()
    |> Map.get(:query)
    |> URI.decode_query()
    |> Map.get("from_token")
  end
end
