defmodule XDR.FixedOpaque do
  @behaviour XDR.Declaration
  @moduledoc """
  This module is in charge of process the Fixed Length Opaque based on the RFC4506 XDR Standard
  """

  defstruct opaque: nil, length: nil

  @typedoc """
  Every Fixed length opaque structure has a opaque which represent the XDR to fix and its length
  """
  @type t :: %XDR.FixedOpaque{opaque: binary | nil, length: integer}

  alias XDR.Error.FixedOpaque, as: FixedOpaqueErr

  @doc """
  this function provides an easy way to create an XDR.FixedOpaque type

  returns a XDR.FixedOpaque struct with the value received as parameter
  """
  @spec new(opaque :: binary, length :: integer) :: t()
  def new(opaque, length), do: %XDR.FixedOpaque{opaque: opaque, length: length}

  @impl XDR.Declaration
  @doc """
  this function is in charge of encode a Fixed Length Opaque into an XDR, it receives an XDR.FixedOpaque structure which
  contains the bytes to encode

  returns an ok tuple with the resulted XDR
  """
  @spec encode_xdr(map()) :: {:ok, binary} | {:error, :not_binary | :not_number | :invalid_length}
  def encode_xdr(%{opaque: opaque}) when not is_binary(opaque),
    do: {:error, :not_binary}

  def encode_xdr(%{length: length}) when not is_integer(length),
    do: {:error, :not_number}

  def encode_xdr(%{opaque: opaque, length: length})
      when length != byte_size(opaque),
      do: {:error, :invalid_length}

  def encode_xdr(%{opaque: opaque, length: length}) when rem(length, 4) === 0,
    do: {:ok, opaque}

  def encode_xdr(%{opaque: opaque, length: length}) when rem(length, 4) != 0 do
    new(opaque <> <<0>>, length + 1)
    |> encode_xdr()
  end

  @impl XDR.Declaration
  @doc """
  this function is in charge of encode a Fixed Length Opaque into an XDR, it receives an XDR.FixedOpaque structure which
  contains the bytes to encode

  returns the resulted XDR
  """
  @spec encode_xdr!(map()) :: binary()
  def encode_xdr!(opaque) do
    case encode_xdr(opaque) do
      {:ok, binary} -> binary
      {:error, reason} -> raise(FixedOpaqueErr, reason)
    end
  end

  @impl XDR.Declaration
  @doc """
  this function is in charge of decode an XDR into a Fixed Length Opaque, it receives an XDR.FixedOpaque structure which
  contains the binary to decode

  returns an :ok tuple with the resulted binary
  """
  @spec decode_xdr(bytes :: binary(), opts :: map()) ::
          {:ok, {t(), binary}}
          | {:error, :not_binary | :not_valid_binary | :not_number | :exceed_length}
  def decode_xdr(bytes, _opts) when not is_binary(bytes), do: {:error, :not_binary}

  def decode_xdr(bytes, _opts) when rem(byte_size(bytes), 4) != 0, do: {:error, :not_valid_binary}

  def decode_xdr(_bytes, %{length: length}) when not is_integer(length), do: {:error, :not_number}

  def decode_xdr(bytes, %{length: length}) when length > byte_size(bytes),
    do: {:error, :exceed_length}

  def decode_xdr(bytes, %{length: length}) do
    required_padding = get_required_padding(length)

    <<fixed_opaque::bytes-size(length), _padding::bytes-size(required_padding), rest::binary>> =
      bytes

    decoded_opaque = new(fixed_opaque, length)

    {:ok, {decoded_opaque, rest}}
  end

  @impl XDR.Declaration
  @doc """
  this function is in charge of decode an XDR into a Fixed Length Opaque, it receives an XDR.FixedOpaque structure which
  contains the binary to decode

  returns the resulted binary
  """
  @spec decode_xdr!(bytes :: binary, opaque :: map()) :: {t(), binary()}
  def decode_xdr!(bytes, opaque) do
    case decode_xdr(bytes, opaque) do
      {:ok, result} -> result
      {:error, reason} -> raise(FixedOpaqueErr, reason)
    end
  end

  @spec get_required_padding(integer()) :: integer()
  defp get_required_padding(length) when rem(length, 4) == 0, do: 0
  defp get_required_padding(length), do: 4 - rem(length, 4)
end