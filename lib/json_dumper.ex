defmodule MobileNumberFormat.JsonDumper do
  @moduledoc false

  def dump_mobile_number_formatting_data(filename \\ "mobile_number_formatting_data.json") do
    json =
      MobileNumberFormat.formatting_data_per_territory()
      |> Enum.map(&Map.put(&1, :regex, Regex.source(&1.regex)))
      |> Jason.encode!()

    file_path = Path.join(:code.priv_dir(:mobile_number_format), filename)

    File.write!(file_path, json, [:write])
  end
end
