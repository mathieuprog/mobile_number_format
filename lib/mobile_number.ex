defmodule MobileNumberFormat.MobileNumber do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :country_code, :string
    field :country_calling_code, :string
    field :national_number, :string
    field :cleaned_national_number, :string
  end

  @fields ~w(country_calling_code national_number)a

  def changeset(mobile, attrs) do
    mobile
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> maybe_validate_and_clean()
  end

  defp maybe_validate_and_clean(changeset) do
    changed? =
      [:country_calling_code, :national_number]
      |> Enum.any?(&Map.has_key?(changeset.changes, &1))

    if changed? do
      validate_and_clean_mobile(changeset)
    else
      changeset
    end
  end

  defp validate_and_clean_mobile(changeset) do
    parsed_data =
      MobileNumberFormat.parse(%{
        country_code: fetch_field!(changeset, :country_code),
        country_calling_code: fetch_field!(changeset, :country_calling_code),
        national_number: fetch_field!(changeset, :national_number)
      })

    case parsed_data do
      :invalid_country_code ->
        add_error(changeset, :invalid_country_code, "country is not valid")

      :invalid_country_calling_code ->
        add_error(changeset, :invalid_country_calling_code, "country calling code is not valid")

      :invalid_number ->
        add_error(changeset, :invalid_number, "mobile number is not valid")

      :insufficient_data ->
        raise "unexpected error"

      parsed_data ->
        {:ok, %{
          country_code: country_code,
          country_calling_code: country_calling_code,
          national_number: cleaned_national_number
        }} = parsed_data

        change(changeset, %{
          country_code: country_code,
          country_calling_code: country_calling_code,
          cleaned_national_number: cleaned_national_number
        })
    end
  end
end
