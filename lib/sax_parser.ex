defmodule MobileNumberFormat.SaxParser do
  @behaviour Saxy.Handler

  def handle_event(:start_document, _prolog, state) do
    {:ok, state}
  end

  def handle_event(:end_document, _data, state) do
    {:ok, state}
  end

  def handle_event(:start_element, {"territory", attributes}, {[], territories}) do
    territory =
      %{
        country_code: Enum.find_value(attributes, fn {k, v} -> k == "id" && v end),
        country_calling_code: Enum.find_value(attributes, fn {k, v} -> k == "countryCode" && v end) |> String.to_integer() |> to_string(),
        national_prefix: Enum.find_value(attributes, fn {k, v} -> k == "nationalPrefix" && v |> String.to_integer() |> to_string() end),
        possible_lengths: nil,
        example: nil,
        regex: nil
      }

    {:ok, {["territory"], [territory | territories]}}
  end

  def handle_event(:start_element, {"mobile", _attributes}, {["territory"], territories}) do
    {:ok, {["mobile", "territory"], territories}}
  end

  def handle_event(:start_element, {"possibleLengths", attributes}, {["mobile", "territory" | _] = tags, territories}) do
    [current_territory | territories] = territories

    current_territory =
      Map.put(
        current_territory,
        :possible_lengths,
        Enum.find_value(attributes, fn {k, v} ->
          if k == "national", do: possible_lengths_to_integer_list(v)
        end))

    {:ok, {["possibleLengths" | tags], [current_territory | territories]}}
  end

  def handle_event(:start_element, {"nationalNumberPattern", _attributes}, {["mobile", "territory" | _] = tags, territories}) do
    {:ok, {["nationalNumberPattern" | tags], territories}}
  end

  def handle_event(:start_element, {"exampleNumber", _attributes}, {["mobile", "territory" | _] = tags, territories}) do
    {:ok, {["exampleNumber" | tags], territories}}
  end

  def handle_event(:start_element, {_name, _attributes}, state) do
    {:ok, state}
  end

  def handle_event(:end_element, _name, {[], territories}) do
    {:ok, {[], territories}}
  end

  def handle_event(:end_element, name, {[name, "mobile", "territory" | _] = tags, territories}) do
    {:ok, {tl(tags), territories}}
  end

  def handle_event(:end_element, "mobile", {["mobile", "territory" | _] = tags, territories}) do
    {:ok, {tl(tags), territories}}
  end

  def handle_event(:end_element, "territory", {["territory" | _] = tags, territories}) do
    {:ok, {tl(tags), territories}}
  end

  def handle_event(:end_element, _name, state) do
    {:ok, state}
  end

  def handle_event(:characters, chars, {["nationalNumberPattern", "mobile" | _] = tags, territories}) do
    [current_territory | territories] = territories

    chars = chars |> String.replace(~r/\s/, "") |> Regex.compile!()
    current_territory = Map.put(current_territory, :regex, chars)

    {:ok, {tags, [current_territory | territories]}}
  end

  def handle_event(:characters, chars, {["exampleNumber", "mobile" | _] = tags, territories}) do
    [current_territory | territories] = territories

    chars = chars |> String.replace(~r/\s/, "")
    current_territory = Map.put(current_territory, :example, chars)

    {:ok, {tags, [current_territory | territories]}}
  end

  def handle_event(:characters, _chars, state) do
    {:ok, state}
  end

  def handle_event(:cdata, _cdata, state) do
    {:ok, state}
  end

  defp possible_lengths_to_integer_list(possible_lengths) do
    possible_lengths
    |> String.split(",")
    |> Enum.map(fn number_or_range ->
      if String.contains?(number_or_range, "[") do
        number_or_range
        |> String.replace_prefix("[", "")
        |> String.replace_suffix("]", "")
        |> String.split("-")
        |> Enum.reduce(nil, fn number, prev_number ->
          if prev_number,
            do: Range.new(String.to_integer(prev_number), String.to_integer(number)),
            else: number
        end)
        |> Enum.to_list()
      else
        String.to_integer(number_or_range)
      end
    end)
    |> List.flatten()
  end
end
