defmodule Base58Test do
  use ExUnit.Case

  test "Base58 encode" do
    tests = [
        {<<"">>, <<"">>},
        {<<0>>, <<"1">>},
        {<<0,0,0,0>>, <<"1111">>},
        {<<0,0,0,0,1>>, <<"11112">>}]
    Enum.map(tests, fn({decoded, encoded}) ->
      assert encoded == Base58.encode(decoded)
    end)
  end

  test "Base58 decode(encode(x)) == x" do
    test_data = [<<>>, <<"">>, <<0>>, <<0,1,0>>, <<0,1,2>>, <<"2">>, <<"1">>, <<"abe">>, <<"123">>, <<"mütter">>]
    Enum.map(test_data, fn(x) ->
      assert x == x |> Base58.encode |> Base58.decode
    end)
  end

  test "padding" do
    assert <<>> == Base58.padding(0, 47)
    assert_raise(FunctionClauseError, fn -> catch_exit(Base58.padding(-1, 47)) end)
    assert_raise(FunctionClauseError, fn -> catch_exit(Base58.padding(-3, 47)) end)
    assert <<47>> == Base58.padding(1, 47)
    assert <<47,47,47>> == Base58.padding(3, 47)
  end

  test "Base58Check" do
    # Check encoding and decoding of a public key.
    raw_pkh = <<142, 8, 250, 232, 150, 38, 188, 245, 46, 119, 237, 68, 29, 154, 114, 24, 35, 185, 158, 69>>

    encoded = Base58.check_encode(0, raw_pkh)
    assert <<"1Dx1iBxp2S7t6hcGQtqzhmDHSwBGArUYqa">> == encoded
    assert {0, ^raw_pkh} = Base58.check_decode(encoded)
  end
end
