defmodule MobileNumberFormatTest do
  use ExUnit.Case
  doctest MobileNumberFormat

  test "formatting_data_per_territory/0" do
    assert is_list(MobileNumberFormat.formatting_data_per_territory())
    assert MobileNumberFormat.formatting_data_per_territory() != []
  end

  test "parse/1" do
    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456", trimmed_national_number_input: "455123456"}} =
      MobileNumberFormat.parse(%{country_code: "BE", country_calling_code: "+32", national_number: "455123456"})
    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456", trimmed_national_number_input: "455123456"}} =
      MobileNumberFormat.parse(%{country_calling_code: "+32", national_number: "455123456"})
    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456", trimmed_national_number_input: "455123456"}} =
      MobileNumberFormat.parse(%{country_code: "BE", national_number: "455123456"})

    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456", trimmed_national_number_input: "455123456"}} =
      MobileNumberFormat.parse(%{country_calling_code: "+32", national_number: "0455123456"})

    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456"}} =
      MobileNumberFormat.parse(%{country_code: "BE", country_calling_code: 32, national_number: "455123456"})
    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456", trimmed_national_number_input: "455/12.34.56"}} =
      MobileNumberFormat.parse(%{country_code: "BE", country_calling_code: 32, national_number: "455/12.34.56"})
    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456", trimmed_national_number_input: "455123456"}} =
      MobileNumberFormat.parse(%{country_code: "BE", country_calling_code: 32, national_number: 455123456})

    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456"}} =
      MobileNumberFormat.parse(%{country_code: "BE", international_number: "+32455123456"})
    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456"}} =
      MobileNumberFormat.parse(%{country_calling_code: "+32", international_number: "+32455123456"})
    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456"}} =
      MobileNumberFormat.parse(%{international_number: "+32455123456"})

    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456", trimmed_national_number_input: "455/1   - 2.34.56"}} =
      MobileNumberFormat.parse(%{international_number: "+32 (0) 455/1   - 2.34.56"})
    assert {:ok, %{country_code: "BE", country_calling_code: "32", national_number: "455123456", trimmed_national_number_input: "455/12.34.56"}} =
      MobileNumberFormat.parse(%{international_number: "+32 (.0) 455/12.34.56"})
    assert :invalid_number =
      MobileNumberFormat.parse(%{international_number: "+32 (1) 455/12.34.56"})

    assert {:ok, %{country_code: "MP", country_calling_code: "1", national_number: "6702345678", trimmed_national_number_input: "67.02.34.56.78"}} =
      MobileNumberFormat.parse(%{international_number: "+167.02.34.56.78"})

    assert :invalid_number == MobileNumberFormat.parse(%{country_calling_code: "+32", national_number: "00455123456"})
    assert :invalid_country_calling_code == MobileNumberFormat.parse(%{country_calling_code: "++32", national_number: "0455123456"})
    assert :invalid_country_calling_code == MobileNumberFormat.parse(%{country_code: "BE", country_calling_code: "+33", national_number: "0455123456"})
    assert :invalid_country_calling_code == MobileNumberFormat.parse(%{country_code: "FR", country_calling_code: "+32", national_number: "0455123456"})
    assert :insufficient_data == MobileNumberFormat.parse(%{national_number: "0455123456"})
  end

  test "country not using national prefix" do
    assert :invalid_number == MobileNumberFormat.parse(%{international_number: "+25311"})
    assert :invalid_number == MobileNumberFormat.parse(%{national_number: "11", country_calling_code: "+253"})

    assert {:ok, %{country_code: "DJ", country_calling_code: "253", national_number: "77831001"}} =
      MobileNumberFormat.parse(%{international_number: "+25377831001"})
    assert {:ok, %{country_code: "DJ", country_calling_code: "253", national_number: "77831001"}} =
      MobileNumberFormat.parse(%{national_number: "77831001", country_calling_code: "+253"})
  end

  test "valid_number?/1" do
    assert MobileNumberFormat.valid_number?(%{country_code: "MP", country_calling_code: "1", national_number: "6702345678"})
    refute MobileNumberFormat.valid_number?(%{country_code: "MP", country_calling_code: "1", national_number: "0006702345678"})
  end

  test "valid_country_calling_code?/1" do
    assert MobileNumberFormat.valid_country_calling_code?("+32")
    assert MobileNumberFormat.valid_country_calling_code?("32")
    assert MobileNumberFormat.valid_country_calling_code?(32)

    refute MobileNumberFormat.valid_country_calling_code?("++32")
    refute MobileNumberFormat.valid_country_calling_code?(" 32")
    refute MobileNumberFormat.valid_country_calling_code?("99")
  end

  test "valid_country_code?/1" do
    assert MobileNumberFormat.valid_country_code?("BE")

    refute MobileNumberFormat.valid_country_code?("be")
    refute MobileNumberFormat.valid_country_code?(" BE")
  end
end
