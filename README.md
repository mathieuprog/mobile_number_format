# MobileNumberFormat

This library helps you parsing and validating mobile phone numbers.

It relies on the data available in Google's [libphonenumber](https://github.com/google/libphonenumber) library. Version `0.1.0` uses the data from version `v8.12.23` of `libphonenumber`.

### `parse/1`

```elixir
assert {:ok, 
  %{
    iso_country_code: "BE", 
    country_calling_code: "32", 
    national_number: "455123456", 
    trimmed_national_number_input: "455/12.34.56"
  }} =
    MobileNumberFormat.parse(%{
      country_calling_code: 32,
      national_number: "0455/12.34.56"
    })
```

The `parse/1` function receives a map that may contain any of these keys:
* `iso_country_code`  
  For instance `"BE"`.

* `country_calling_code`  
  For instance `"32"`, `"+32"` or `32`.
  Local international call prefixes are not supported (only the prefix `+` is supported).
  
* `national_number`  
  For instance the Belgian national number `"455/12.34.56"`. National prefixes are supported `"0455/12.34.56"`.

* `international_number`
  For instance `"+32 455/12.34.56"`. A national prefix may be added in parentheses `"+32 (0)455/12.34.56"`.

In case the number is valid, the tuple `{:ok, data}` is returned where `data` is a map containing the 4 key/values mentioned above.

In case of error, the following atoms may be returned:

* `:invalid_iso_country_code`
* `:invalid_country_calling_code`
* `:invalid_number`
* `:insufficient_data`

### `valid_number?/1`

Same as `parse/1` but returns `true` or `false` whether the number is valid or not.

### `valid_country_calling_code?/1`

Checks whether the given country calling code is valid or not.

### `valid_iso_country_code?/1`

Checks whether the given ISO country code is valid or not.

### `formatting_data_per_territory/0`

Returns a list of all the formatting rules. Example of formatting rules (for Belgium):

```elixir
%{                                      
  country_calling_code: "32",           
  example: "470123456",                 
  iso_country_code: "BE",               
  national_prefix: "0",                 
  possible_lengths: [9],               
  regex: ~r/4[5-9]\d{7}/                
}
```

## Installation

Add `mobile_number_format` for Elixir as a dependency in your `mix.exs` file:

```elixir
def deps do
  [
    {:mobile_number_format, "~> 0.1.0"}
  ]
end
```

## HexDocs

HexDocs documentation can be found at [https://hexdocs.pm/mobile_number_format](https://hexdocs.pm/mobile_number_format).
