defmodule MobileNumberFormat.Compiler do
  @moduledoc false

  require MobileNumberFormat.SaxParser

  alias MobileNumberFormat.SaxParser

  def compile() do
    {:ok, {_, territories}} =
      Path.join(:code.priv_dir(:mobile_number_format), "PhoneNumberMetadata.xml")
      |> File.stream!()
      |> Stream.filter(&!Regex.match?(~r/^\s*<--(.*?)-->\s*$/, &1))
      |> Stream.filter(&!Regex.match?(~r/^\s*$/, &1))
      |> Saxy.parse_stream(SaxParser, {[], []})

    territories =
      territories
      |> Enum.filter(&(&1.regex))
      |> Enum.sort_by(fn territory -> territory.country_calling_code end)

    contents = [
      quote do
        def formatting_data_per_territory() do
          unquote(Macro.escape(territories))
        end

        def valid_number?(%{} = data) do
          match?({:ok, _}, parse(data))
        end

        def valid_country_calling_code?(country_calling_code) do
          fetch_by_country_calling_code(country_calling_code) != :error
        end

        def valid_country_code?(country_code) do
          fetch_by_country_code(country_code) != :error
        end

        def parse(%{} = data) do
          international_number_arg = Map.get(data, :international_number, nil)
          national_number_arg = Map.get(data, :national_number, nil)
          country_calling_code_arg = Map.get(data, :country_calling_code, nil)
          country_code_arg = Map.get(data, :country_code, nil)

          cond do
            country_code_arg || country_calling_code_arg ->
              fetch_by_country_code_or_country_calling_code(country_code_arg, country_calling_code_arg)
              |> case do
                {:ok, formatting_rules} ->
                  formatting_rules_list = List.wrap(formatting_rules)

                  cond do
                    national_number_arg ->
                      do_parse(formatting_rules_list, national_number_arg, :national)

                    international_number_arg ->
                      do_parse(formatting_rules_list, international_number_arg, :international)
                  end

                error ->
                  error
              end

            international_number_arg ->
              do_parse(nil, international_number_arg, :international)

            true ->
              :insufficient_data
          end
        end

        defp do_parse(formatting_rules_list, national_number_arg, :national) do
          national_number_arg = national_number_arg |> to_string()
          cleaned_national_number = national_number_arg |> String.replace(~r/[^\d]/, "")

          Enum.find_value(formatting_rules_list, fn formatting_rules ->
            %{
              country_calling_code: country_calling_code,
              country_code: country_code,
              national_prefix: national_prefix
            } = formatting_rules

            if match_national_number?(formatting_rules, cleaned_national_number) do
              %{"trimmed_national_number_input" => trimmed_national_number_input} =
                Regex.named_captures(~r/(?<trimmed_national_number_input>\d.*\d)/, national_number_arg)

              {:ok, %{
                country_code: country_code,
                country_calling_code: country_calling_code,
                national_number: cleaned_national_number,
                trimmed_national_number_input: trimmed_national_number_input
              }}
            else
              if national_prefix do
                cleaned_national_number_without_prefix = cleaned_national_number |> String.replace_prefix(national_prefix, "")

                if(
                  cleaned_national_number != cleaned_national_number_without_prefix
                  && match_national_number?(formatting_rules, cleaned_national_number_without_prefix)
                ) do
                  national_number_without_prefix_arg =
                    national_prefix
                    |> String.graphemes()
                    |> Enum.reduce(national_number_arg, fn digit, national_number_arg ->
                      String.replace(national_number_arg, digit, "", global: false)
                    end)

                  %{"trimmed_national_number_input" => trimmed_national_number_input} =
                    Regex.named_captures(~r/(?<trimmed_national_number_input>\d.*\d)/, national_number_without_prefix_arg)

                  {:ok, %{
                    country_code: country_code,
                    country_calling_code: country_calling_code,
                    national_number: cleaned_national_number_without_prefix,
                    trimmed_national_number_input: trimmed_national_number_input
                  }}
                end
              end
            end
          end)
          |> case do
            nil ->
              :invalid_number

            result ->
              result
          end
        end

        defp do_parse(nil, international_number_arg, :international) do
          cleaned_international_number = international_number_arg |> to_string() |> String.replace(~r/[^\d]/, "")

          unquote(Macro.escape(territories))
          |> Enum.filter(&String.starts_with?(cleaned_international_number, &1.country_calling_code))
          |> do_parse(international_number_arg, :international)
        end

        defp do_parse(formatting_rules_list, international_number_arg, :international) do
          international_number_arg = international_number_arg |> to_string()

          Enum.find_value(formatting_rules_list, fn formatting_rules ->
            %{
              country_calling_code: country_calling_code,
              country_code: country_code,
              national_prefix: national_prefix
            } = formatting_rules

            national_number_arg =
              country_calling_code
              |> String.graphemes()
              |> Enum.reduce(international_number_arg, fn digit, international_number_arg ->
                String.replace(international_number_arg, digit, "", global: false)
              end)

            if national_prefix do
              case Regex.named_captures(~r/(?<national_prefix>\d+?)\s*\)(?<national_number>.*)$/, national_number_arg) do
                nil ->
                  %{national_number_arg: national_number_arg}

                %{"national_number" => matched_national_number, "national_prefix" => matched_national_prefix} ->
                  matched_national_prefix = matched_national_prefix |> String.replace(~r/[^\d]/, "")

                  if national_prefix == matched_national_prefix do
                    %{national_number_arg: matched_national_number}
                  end
              end
            else
              %{national_number_arg: national_number_arg}
            end
            |> case do
              %{national_number_arg: national_number_arg} ->
                cleaned_national_number = national_number_arg |> String.replace(~r/[^\d]/, "")

                if match_national_number?(formatting_rules, cleaned_national_number) do
                  %{"trimmed_national_number_input" => trimmed_national_number_input} =
                    Regex.named_captures(~r/(?<trimmed_national_number_input>\d.*\d)/, national_number_arg)

                  {:ok, %{
                    country_code: country_code,
                    country_calling_code: country_calling_code,
                    national_number: cleaned_national_number,
                    trimmed_national_number_input: trimmed_national_number_input
                  }}
                end

              nil ->
                nil
            end
          end)
          |> case do
            nil ->
              :invalid_number

            result ->
              result
          end
        end

        defp match_national_number?(%{regex: regex, possible_lengths: possible_lengths}, national_number) do
          String.length(national_number) in possible_lengths && Regex.match?(regex, national_number)
        end

        defp fetch_by_country_code(country_code) do
          unquote(Macro.escape(territories))
          |> Enum.find(&(&1.country_code == country_code))
          |> case do
            nil ->
              :error

            formatting_rules ->
              {:ok, formatting_rules}
          end
        end

        defp fetch_by_country_calling_code(country_calling_code) do
          country_calling_code = clean_country_calling_code(country_calling_code)

          unquote(Macro.escape(territories))
          |> Enum.filter(&(&1.country_calling_code == country_calling_code))
          |> case do
            [] ->
              :error

            [formatting_rules] ->
              {:ok, formatting_rules}

            formatting_rules_list ->
              {:ok, formatting_rules_list}
          end
        end

        defp fetch_by_country_code_or_country_calling_code(country_code_arg, country_calling_code_arg) do
          cond do
            country_code_arg && country_calling_code_arg ->
              case fetch_by_country_code(country_code_arg) do
                :error ->
                  :invalid_country_code

                {:ok, %{country_calling_code: country_calling_code}} ->
                  if clean_country_calling_code(country_calling_code_arg) != country_calling_code do
                    :invalid_country_calling_code
                  else
                    fetch_by_country_code_or_country_calling_code(country_code_arg, nil)
                  end
              end

            country_code_arg ->
              case fetch_by_country_code(country_code_arg) do
                :error ->
                  :invalid_country_code

                {:ok, formatting_rules} ->
                  {:ok, formatting_rules}
              end

            country_calling_code_arg ->
              case fetch_by_country_calling_code(country_calling_code_arg) do
                :error ->
                  :invalid_country_calling_code

                {:ok, formatting_rules} ->
                  {:ok, formatting_rules}
              end
          end
        end

        defp clean_country_calling_code(country_calling_code) do
          country_calling_code = country_calling_code |> to_string()

          country_calling_code
          |> String.pad_leading(String.length(country_calling_code) + 1, "+")
          |> String.replace_prefix("+", "")
          |> Integer.parse()
          |> case do
            {number, ""} ->
              number |> to_string()

            :error ->
              :error
          end
        end
      end
    ]

    module = :"Elixir.MobileNumberFormat"
    Module.create(module, contents, Macro.Env.location(__ENV__))
    :code.purge(module)
  end
end
