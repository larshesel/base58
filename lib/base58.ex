defmodule Base58 do
  @moduledoc """
  Base58 implements the bitcoin Base58Check as well as raw base58
  encoding and decoding functionalities.
  """

  # Bitcoin base58 alphabet.
  @alphabet ~c(123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz)
  @alpha_at_zero ?1
  @radix 58

  @doc """
  check_encode implements the Base58Check encoding.

  Note version must be in the interval [0,255].
  """
  @spec check_encode(integer, binary) :: binary
  def check_encode(version, payload) when is_integer(version) and is_binary(payload) do
    data = <<version :: 8, payload :: binary>>
    <<checksum :: binary-size(4), _ :: binary>> = Crypto.dsha256(data)
    encode(<<data :: binary, checksum :: binary>>)
  end

  @doc """
  check_decode implements Base58Check decoding.
  """
  @spec check_decode(binary) :: {integer, binary} | {:error, :invalid_checksum}
  def check_decode(data) do
    <<version :: 8, data :: binary>> = decode(data)
    payload = :erlang.binary_part(data, {0, byte_size(data) - 4})
    checksum = :erlang.binary_part(data, {byte_size(data), -4})
    case Crypto.dsha256(<<version :: 8, payload :: binary>>) do
      <<^checksum :: binary-size(4), _ :: binary>> ->
        {version, payload}
      _ ->
        {:error, :invalid_checksum}
    end
  end

  @doc """
  encode implements Base58 encoding.
  """
  @spec encode(binary) :: binary
  def encode(decoded) when is_binary(decoded) do
    len = bit_size(decoded)
    <<val :: integer-size(len)>> = decoded
    # take num modulus radix until it is zero
    nonzero = encode_nonzero(val, <<>>)

    zeros = count_leading(decoded, 0, 0)
    padding = padding(zeros, @alpha_at_zero)

    <<padding :: binary, nonzero :: binary>>
  end

  defp count_leading(bin, byte, count) do
    case bin do
      <<^byte :: 8, rest :: binary>> ->
        count_leading(rest, byte, count + 1)
      _ ->
        count
    end
  end

  @spec padding(integer, integer) :: binary
  def padding(0, _byte) do
    <<>>
  end
  def padding(len, byte) when len > 0 do
    for _ <- 1..len, into: <<>>, do: <<byte>>
  end

  defp encode_nonzero(0, res) do
    res
  end
  defp encode_nonzero(val, res) do
    rem = rem(val, @radix)
    quot = div(val, @radix)
    # TODO(lhc): This is O(n), maybe replace with something O(1)
    newletter = Enum.at(@alphabet, rem)
    encode_nonzero(quot, <<newletter :: 8, res :: binary>>)
  end

  @doc """
  decode implements Base58 decoding.
  """
  @spec decode(binary) :: binary
  def decode(<<>>) do
    <<>>
  end
  def decode(encoded) when is_binary(encoded) do
    # TODO: This is likely not the most efficient way to reverse a
    # binary.
    decoded = encoded |> :erlang.binary_to_list |>
      Enum.reverse |> :erlang.list_to_binary |>
      decode_nonzero(0, 1)

    leading_zeros = count_leading(encoded, ?1, 0)

    <<0 :: size(leading_zeros)-unit(8), decoded :: binary>>
  end

  defp decode_nonzero(<<>>, 0, _) do
    <<>>
  end
  defp decode_nonzero(<<>>, val, _) do
    :binary.encode_unsigned(val)
  end
  defp decode_nonzero(<<letter :: 8, rest :: binary>>, val, multiplier) do
    # TODO(lhc): This is O(n), maybe replace with something O(1)
    digit = Enum.find_index(@alphabet, &(&1 == letter))
    tmp = digit * multiplier
    val = val + tmp
    decode_nonzero(rest, val, multiplier*58)
  end
end
