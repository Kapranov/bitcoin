# How to calculate Bitcoin address in Elixir

*A technical guide to generate Bitcoin addresses using Elixir*

Public key cryptography is any cryptographic system that uses **pairs of
keys**:

* **private keys** - which are known only to the owner,
* **public  keys** - which may be distributed widely.

In this system,  a person can combine a message with  a *private key* to
create  a  *signature*  on  the  message.  Anyone with the corresponding
*public key* can use it to **verify** whether the *signature* was  valid
- **signed** by the owner of the appropriate *private key*.

```
╔════════╗  ╔════════╗  ╔═════════════╗  ╔════════════════╗
║ Signer ╟──╢  DATA  ╟──╢ Encryption  ╟──╢ Digital Signed ║
╚════════╝  ╚════════╝  ║ Private Key ║  ║    Document    ║
                        ╚═════════════╝  ╚═══════╦════════╝
                                                 ║
                                                 ║
     ╔═══════════════════════════════════════════╝
     ║
     V
╔═══════════╗   ╔════════════╗   ╔══════════════════════╗   ╔══════════╗
║ Hash      ║   ║ Decryption ║   ║ Hash Value Signature ║   ║          ║
║ Algorithm ╠═══╣ Public Key ╠═══╣ is valid if two hash ╠══>║ RECEIVER ║
╚═══════════╝   ╚════════════╝   ║ values match         ║   ║          ║
                                 ╚══════════════════════╝   ╚══════════╝
```

Let's  see  how  to  implement  these functionalities in Elixir. We will
leverage  *crypto*  module  from  *erlang*   which  provides  a  set  of
convenient  cryptographic operations. We are particularly interested in:

* Hash functions
* Hmac functions
* Digital signatures Digital Signature Standard (DSS)
* Elliptic Curve Digital Signature Algorithm (ECDSA)

## KeyPair

Generating a keypair is as simple as calling a specific function with
appropriate attributes:

```elixir
defmodule BitcoinAddress.Primary do
  @moduledoc false

  def keypair do
    with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
      do: {Base.encode16(public_key), Base.encode16(private_key)}
  end
end
```

```sh
iex|1 ▶ BitcoinAddress.Primary.keypair
{
  "04BC2BB248E2EFCD36A4F88050137FB531476F937D36A3351425453F8CB12DDDC3DFBB623EA414C2C9788AB2329401C3FCE0725F57154B30AD85C862A72E8882F2",
  "2BA9695DE3EF229E23A5532C673C0A2AB2E213044572EE0AC6F0556499669D1A"
}
```

You  don't  need  anything else to create an `ECDH`-compliant keys in a
convenient to use `Base16` (hexadecimal) format.

If you want to store such keys, you can persist them on a disk or use a
special kind of "database" called wallet.  It's a place, either digital
or  physical,  which,  in  its basic form, keeps your keys secretly. It
doesn't  require  any connection  to  the network or a reference to the
Blockchain.

```elixir
defmodule BitcoinAddress.Primary do
  @moduledoc false

  def keypair do
    {_, private_key} =
      with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
        do: {Base.encode16(public_key), Base.encode16(private_key)}
    {:ok, private_key}
  end

  def write do
    private_key = keypair() |> elem(1)
    with file_path = ".keys/key",
      :ok <- File.write(file_path, private_key) do
        {file_path, private_key}
      else
        {:error, error} -> :file.format_error(error)
      end
  end
end
```

```sh
iex|1 ▶ BitcoinAddress.Primary.keypair |> elem(1)
iex|2 ▶ BitcoinAddress.Primary.write
{
  ".keys/keys",
  "8872CFBC3BFFEE5D190BB880C14D5528262982B4D57009061F12E3F60727DD92"
}
```

The create private function by keypair, and a Map to result:

```elixir
defmodule BitcoinAddress.Primary do
  @moduledoc false

  @dir_keypair ".keys/keys"

  def write do
    private_key = keypair() |> elem(1)
    with file_path = @dir_keypair,
      :ok <- File.write(file_path, private_key) do
        %{"dir": file_path, "key": private_key}
      else
        {:error, error} -> :file.format_error(error)
      end
  end

  defp keypair do
    {_, private_key} =
      with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
        do: {Base.encode16(public_key), Base.encode16(private_key)}
    {:ok, private_key}
  end
end
```

```sh
iex|1 ▶ BitcoinAddress.Primary.write
%{
  dir: ".keys/keys",
  key: "049DD8AFF80EBEAB210DF5C6A11DC19CE4E27E78854EB4E96A6F78EC9CB0E6F3"
}
```

## Signature

Once  you  have  your  keypair  generated  and  stored, you can use your
*private key*  to sign a message you want to send.

Keep  in  mind  that **you  have  to decode both** *private key* **and**
*public key* from `Base16` encoded  string  into binary strings firstly!

```elixir
signature = :crypto.sign(
  :ecdsa,
  :sha256,
  "message",
  [private_key, :secp256k1]
)
```

```elixir
def sign do
  private_key = File.read(".keys/keys")
                |> Tuple.to_list
                |> List.delete(:ok)
                |> List.to_string
                |> String.split(",")
                |> List.first
                |> Base.decode16
                |> elem(1)

  signature = :crypto.sign(
    :ecdsa,
    :sha256,
    "message",
    [private_key, :secp256k1]
  )
  {:ok, signature}
end
```

```sh
iex|1 ▶ BitcoinAddress.Primary.sign
{
  :ok,
  <<48, 69, 2, 32, 24, 144, 0, 84, 121, 77, 110, 189, 49, 82, 103, 21,
    63, 102, 59, 228, 200, 76, 8, ...>>
}
```
With  the  generated   *signature*  we  can  verify  if the owner of the
*public key*   actually  signed   the   message  without  knowing  their
*private key*:

```elixir
:crypto.verify(
  :ecdsa,
  :sha256,
  "message",
  signature,
  [public_key, :secp256k1]
)
```

```elixir
def verify do
  public_key = File.read(".keys/keys")
               |> Tuple.to_list
               |> List.delete(:ok)
               |> List.to_string
               |> String.split(",")
               |> List.last
               |> Base.decode16
               |> elem(1)

  signature = sign() |> elem(1)

  varify = :crypto.verify(
   :ecdsa,
   :sha256,
   "message",
   signature,
   [public_key, :secp256k1]
  )
  {:ok, varify}
end
```

```sh
iex|1 ▶ BitcoinAddress.Primary.verify
{:ok, true}
```

A final of the result:

```elixir
def write do
  keys = keypair()
  public_key  = keys |> elem(0)
  private_key = keys |> elem(1)
  with file_path = @dir_keypair,
    :ok <- File.write(file_path, "#{[public_key, private_key] |> Enum.join(",")}") do
      %{"dir": file_path, "pri": private_key, "pub": public_key}
    else
      {:error, error} -> :file.format_error(error)
    end
end

def sign do
  private_key = File.read(".keys/keys")
                |> Tuple.to_list
                |> List.delete(:ok)
                |> List.to_string
                |> String.split(",")
                |> List.first
                |> Base.decode16
                |> elem(1)

  signature = :crypto.sign(
    :ecdsa,
    :sha256,
    "message",
    [private_key, :secp256k1]
  )
  {:ok, signature}
end

def verify do
  public_key = File.read(".keys/keys")
               |> Tuple.to_list
               |> List.delete(:ok)
               |> List.to_string
               |> String.split(",")
               |> List.last
               |> Base.decode16
               |> elem(1)

  signature = sign() |> elem(1)

  varify = :crypto.verify(
    :ecdsa,
    :sha256,
    "message",
    signature,
    [public_key, :secp256k1]
  )
  {:ok, varify}
end
```

## Address

From  a  technical perspective,  a **Bitcoin  address  is  a hash of the
public  portion  of a public/private keypair**.  It's a string of digits
and characters.

It **represents a possible destination for a Bitcoin payment**  and  can
be shared with anyone who wants to send you money. That's why it appears
most commonly as the "recipient" of the funds.

Addresses can be **generated at no cost** by any user of Bitcoin. People
can  have  many  different addresses and a unique address should be used
for each transaction.  Creating  them  can be done **without an Internet
connection** and does not require any contact or  registration  with the
Bitcoin network.

The entire process looks as follows:

```sh
              Public Key to Bitcoin Address
              ╔═══════════════════════════╗
              ║         Public Key        ║
              ╚══════════════╦════════════╝
                             ║
                  ╔          V         ╗
                  ║ ╔════════╩═══════╗ ║
  "Double Hash"   ║ ║     SHA256     ║ ║
       or         ║ ╚════════╦═══════╝ ║
    HASH160       ║          V         ║
                  ║ ╔════════╩═══════╗ ║
                  ║ ║   RIPEMD160    ║ ║
                  ║ ╚════════╦═══════╝ ║
                  ╚          ║         ╝
                             V
              ╔══════════════╩════════════╗
              ║       Public Key Hash     ║
              ║     (20 bytes/160 bits)   ║
              ╚══════════════╦════════════╝
                             V
              ╔══════════════╩════════════╗
              ║      Base58Check Encode   ║
              ║  with 0x00 version prefix ║
              ╚══════════════╦════════════╝
                             ║
                             ║
                             V
         ╔═══════════════════════════════════════╗
         ║            Bitcoin Address            ║
         ║ (Base58Check Encoded Public Key Hash) ║
         ╚═══════════════════════════════════════╝
```
And it can be described programatically as:

```elixir
private_key
|> KeyPair.to_public_key()
|> hash_160()
|> prepend_version_byte(network)
|> Check.call()
|> Encode.call()
```
Let's divide it into smaller steps and implement each part of it.

```elixir
defmodule BitcoinAddress.Primary do
  @moduledoc false

  @dir_keypair ".keys/keys"

  def write do
    keys = keypair()
    public_key  = keys |> elem(0)
    private_key = keys |> elem(1)
    with file_path = @dir_keypair,
      :ok <- File.write(file_path, "#{[private_key, public_key] |> Enum.join(", ")}") do
        %{"dir": file_path, "pri": private_key, "pub": public_key}
      else
        {:error, error} -> :file.format_error(error)
      end
  end

  def sign do
    private_key = get_private_key() |> base.decode16 |> elem(1)
    signature = :crypto.sign(
      :ecdsa,
      :sha256,
      "message",
      [private_key, :secp256k1]
    )
    {:ok, signature}
  end

  def verify do
    public_key = get_public_key() |> base.decode16 |> elem(1)
    signature = sign() |> elem(1)

    varify = :crypto.verify(
    :ecdsa,
    :sha256,
    "message",
    signature,
    [public_key, :secp256k1]
    )
    {:ok, varify}
  end

  def to_public_key do
    {public_key, args} = :crypto.generate_key(:ecdh, :secp256k1, get_private_key())
    {public_key, args}
  end

  defp keypair do
    {public_key, private_key} =
      with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
        do: {Base.encode16(public_key), Base.encode16(private_key)}
    {public_key, private_key}
  end

  defp get_private_key do
    File.read(".keys/keys")
    |> Tuple.to_list
    |> List.delete(:ok)
    |> List.to_string
    |> String.split(",")
    |> List.first
  end

  defp get_public_key do
    File.read(".keys/keys")
    |> Tuple.to_list
    |> List.delete(:ok)
    |> List.to_string
    |> String.split(",")
    |> List.last
    |> String.trim
  end
end
```
## Public Key

Generating *public key* from *private key* is again very simple. It's
based on elliptic curve manipulation (irreversible cryptographic
algorithm). To get it, it's enough to do:

```elixir
{public_key, _} = :crypto.generate_key(:ecdh, :secp256k1, private_key)
```
```sh
iex|1 ▶ private_key = File.read(".keys/keys") |>
...|1 ▶   Tuple.to_list |>
...|1 ▶   List.delete(:ok) |>
...|1 ▶   List.to_string |>
...|1 ▶   String.split(",") |>
...|1 ▶   List.first
"053A00A99FDF89DDAC42F33F59B2EE7321BCF8C3CECBA0E51D6FB9D500301B45"}

iex|2 ▶ {public_key, _} = :crypto.generate_key(:ecdh, :secp256k1, private_key)
{<<4, 223, 93, 86, 104, 6, 82, 243, 164, 17, 36, 42, 95, 215, 158, 17,
   150, 3, 200, 199, 228, 33, 56, 194, ...>>,
 "053A00A99FDF89DDAC42F33F59B2EE7321BCF8C3CECBA0E51D6FB9D500301B45"}
```
Now you have a *public key* derived from the private one.

```elixir
def to_public_key do
  {public_key, args} = :crypto.generate_key(:ecdh, :secp256k1, get_private_key())
  {public_key, args}
end
```

```sh
iex|1 ▶ BitcoinAddress.Primary.to_public_key
{<<4, 223, 93, 86, 104, 6, 82, 243, 164, 17, 36, 42, 95, 215, 158, 17,
   150, 3, 200, 199, 228, 33, 56, 194, ...>>,
 "053A00A99FDF89DDAC42F33F59B2EE7321BCF8C3CECBA0E51D6FB9D500301B45"}
```
## Hashing

The next step is to apply a one-way function that produces a fingerprint
of the given input. The specific algorithms used for that are:

* Secure Hash Algorithm `sha256`
* RACE Integrity Primitives Evaluation Message Digest `ripemd160`

Starting with the public key, we compute `sha256` on it and then apply
`ripemd160`  on  the  result, producing a `160-bit` number. The `hash`
function is very simple: `:crypto.hash(algorithm, data)`

```elixir
def hash(data, algorithm), do: :crypto.hash(algorithm, data)
```

```sh
iex|1 ▶ public_key = BitcoinAddress.Primary.to_public_key |> elem(0)
<<4, 223, 93, 86, 104, 6, 82, 243, 164, 17, 36, 42, 95, 215, 158, 17,
  150, 3, 200, 199, 228, 33, 56, 194, 66, ...>>
iex|2 ▶ public_key |>
        BitcoinAddress.Primary.hash(:sha256) |>
        BitcoinAddress.Primary.hash(:ripemd160)
<<22, 41, 219, 113, 107, 58, 170, 41, 136, 50, 26, 115, 88, 68, 113, 61,
  159, 122, 45, 154>>
```
An examples with Hashes:

```elixir
public_key = BitcoinAddress.Primary.to_public_key |> elem(0)

# To get the binary hash:
:crypto.hash(:sha, public_key)

# to get the hex digest from that:
:crypto.hash(:sha256, public_key) |> Base.encode16

# hashing multiple things in a list
:crypto.hash(:sha256, [3, "things", "!"]) |> Base.encode16

iex(1)> :crypto.hash(:sha, "whatever")
iex(1)> :crypto.hash(:sha256, "whatever") |> Base.encode16
iex(1)> :crypto.hash(:sha256, [3, "things", "!"]) |> Base.encode16

# Streaming hashing
sha = :crypto.hash_init(:sha256)
sha = :crypto.hash_update(sha, "2")
sha = :crypto.hash_update(sha, "things")
sha_binary = :crypto.hash_final(sha)
sha_hex = sha_binary |> Base.encode16 |> String.downcase
```

```elixir
def to_public_hash do
  public_key = to_public_key() |> elem(0)

  public_key
  |> hash(:sha256)
  |> hash(:ripemd160)
end
```

## Network ID

Blockchain-based currencies use encoded strings, which are `Base58Check`
encoded. The encoding includes a prefix (traditionally a single *version
byte*), which affects the leading symbol in the encoded result.

These are two most common prefixes which are in use in the Bitcoin
codebase:

```elixir
@version_bytes %{
  main: <<0x00>>,
  test: <<0x6F>>
}
```
As you see, we use `0` for the main network and `111` for the test one.

```elixir
@version_bytes
|> Map.get(network)
|> Kernel.<>(public_hash)
```

To convert a public hash into `Base58Check` format, we need to firstly
prepend  it  with a *version byte* which helps to identify the encoded
data.

```elixir
def prepend_version do
  public_hash = to_public_hash()
  network = :main

  @version_bytes
  |> Map.get(network)
  |> Kernel.<>(public_hash)
end
```

## Base58 check

`Base58` number system uses `58` characters and a checksum to help human
readability,  avoid  ambiguity  and  protect against errors. It has also
benefits  in  terms  of  brevity  as  long  numbers are represented more
compact in mixed-alphanumeric systems with a base higher than `10`.

Here is the general flow of performing `Base58Check` check:

```sh
                  BASE58CHECK ENCODING
              ╔═══════════════════════════╗
              ║           PAYLOAD         ║
              ╚═══════════════════════════╝
1. Add Version prefix                                  2.  Hash  Version
                                                       Prefix + Playload
╔═════════════╦═══════════════════════════╗            ╔═══════════════╗
║   VERSION   ║           PAYLOAD         ╠═──────────>║     SHA256    ║
╚═════════════╩═══════════════════════════╝            ╠═══════════════╣
                                                       ║     SHA256    ║
                                                       ╠═══════════════╣
                                                       ║ first 4 bytes ║
                                                       ╚════════╦══════╝
╔═════════════╦═══════════════════════════╦══════════╗          ║
║   VERSION   ║           PAYLOAD         ║ CHECKSUM ╟<═════════╝
╚═════════════╩══════════════╦════════════╩══════════╝
                             ║                         3.  Add  first  4
                             ║                         bytes as checksum
              ╔══════════════╩════════════╗
              ║        BASE 58 ENCODE     ║
              ╚══════════════╦════════════╝
4. Encode in Base 58         ║
╔════════════════════════════╩═══════════════════════╗
║              BASE58CHECK ENCODED PAYLOAD           ║
╚════════════════════════════════════════════════════╝
```
Which can be represented programatically as:

```elixir
versioned_hash
|> sha256()
|> sha256()
|> checksum()
|> append(versioned_hash)
```
So, to perform `Base58Check` we should cover the following steps:

1. Perform double `SHA-256` hash on the versioned payload.

```elixir
:crypto.hash(:sha256, data)
```

2. Take the first `4` bytes of the second `SHA-256` hash as a checksum.

```elixir
<<checksum::bytes-size(4), _::bits>> = hash
```
3. Append checksum to the initial public hash.

```elixir
versioned_hash <> checksum
```
The result is the `25-byte` *Binary Bitcoin Address*.

```elixir
@checksum_length 4

def check do
  versioned_hash = prepend_version()

  versioned_hash
  |> sha256()
  |> sha256()
  |> checksum()
  |> append(versioned_hash)
end

defp get_private_key do
  File.read(".keys/keys")
  |> Tuple.to_list
  |> List.delete(:ok)
  |> List.to_string
  |> String.split(",")
  |> List.first
end

defp prepend_version do
  public_hash = to_public_hash()
  network = :main

  @version_bytes
  |> Map.get(network)
  |> Kernel.<>(public_hash)
end

defp to_public_key do
  {public_key, args} = :crypto.generate_key(:ecdh, :secp256k1, get_private_key())
  {public_key, args}
end

defp to_public_hash do
  public_key = to_public_key() |> elem(0)

  public_key
  |> hash(:sha256)
  |> hash(:ripemd160)
end

defp hash(data, algorithm), do: :crypto.hash(algorithm, data)
defp sha256(data), do: :crypto.hash(:sha256, data)
defp checksum(<<checksum::bytes-size(@checksum_length), _::bits>>), do: checksum
defp append(checksum, hash), do: hash <> checksum
```

## Base58 encoding

Most Bitcoin addresses are `34` characters. It's because `Base58` format
consist of random digits and uppercase  and  lowercase letters, with the
exception that the uppercase letter `O`, uppercase letter `I`, lowercase
letter  `1`,  and  the  number  `0`  are  never  used  to prevent visual
ambiguity. Another advantage is lack of line-breaks, either  in  emails-
chats or while double-clicking and copying, as there's no punctuation to
break at.

To encode a big-endian series of bytes from the previous step, we'll use
a regular mathematical  bignumber division with the *alphabet* described
above.

At  the  very  beginning, we need to define a recursive function and, in
case of passing a binary, convert it to a number.

Once  converted,  we  pass  our binary-come-number into a recursive call
along with the beginning of our `input`, and an empty string.

We continue recursing until we reduce our `input` down to `0`.  In  that
case, we'll return the `acc` we've built up.

```elixir
def call(input, acc \\ "")
def call(0, acc), do: acc
def call(input, acc)
    when is_binary(input) do
  input
  |> :binary.decode_unsigned()
  |> call(acc)
  |> prepend_zeros(input)
end
```
For each recursive call to `call/2`,  we divide our `input` by `58`  and
find  the  reminder.  We  use  that  remainder  to take a character from
`alphabet`, and append the current `acc` to it.

```elixir
def call(input, acc) do
  input
  |> div(58)
  |> call(extended_hash(input, acc))
end

defp extended_hash(input, acc) do
  "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  |> String.at(rem(input, 58))
  |> apend(acc)
end
```
If  we  encode  binaries with leading zero bytes, we need to count them,
encode them manually, and prepend them to the final `acc`.

```elixir
defp prepend_zeros(acc, input) do
  input
  |> encode_zeros()
  |> apend(acc)
end

defp encode_zeros(input) do
  input
  |> leading_zeros()
  |> duplicate_zeros()
end
```
We  use `:binary.bin_to_list` from `erlang` to convert our binary into a
list of bytes, and  `Enum.find_index` to find the first byte in our list
that isn't zero. This index value is equivalent to the number of leading
zero bytes in our binary.

```elixir
defp leading_zeros(input) do
  input
  |> :binary.bin_to_list()
  |> Enum.find_index(&(&1 != 0))
end
```
Next,  we'll write a function to manually encode these leading zeros. We
simply grab  the character  in  our  *alphabet* that maps to a zero byte
(`1` - the first one), and duplicate it as many times as we need.

```elixir
defp duplicate_zeros(count) do
  "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  |> String.first()
  |> String.duplicate(count)
end
```
Now we should be able to encode binaries with leading zero bytes and see
their resulting `1` values in our final hash.

```elixir
@alphabet "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
@length String.length(@alphabet)

def call(input, acc \\ "")
def call(0, acc), do: acc

def call(input, acc) when is_binary(input) do
  input
  |> :binary.decode_unsigned()
  |> call(acc)
  |> prepend_zeros(input)
end

def call(input, acc) do
  input
  |> div(@length)
  |> call(extended_hash(input, acc))
end

defp extended_hash(input, acc) do
  @alphabet
  |> String.at(rem(input, @length))
  |> append(acc)
end

defp prepend_zeros(acc, input) do
  input
  |> encode_zeros()
  |> append(acc)
end

defp encode_zeros(input) do
  input
  |> leading_zeros()
  |> duplicate_zeros()
end

defp leading_zeros(input) do
  input
  |> :binary.bin_to_list()
  |> Enum.find_index(&(&1 != 0))
end

defp duplicate_zeros(count) do
  @alphabet
  |> String.first()
  |> String.duplicate(count)
end

defp append(prefix, postfix), do: prefix <> postfix
```
## Summary

A common misconception  is  that *walletes*   contain  Bitcoins. Now you
know,  they  contain  only  keys.  The  balances  are  recorded  in  the
Blockchain  and  can be tracked by *addresses* .  In a sense, a *wallet*
is really a keychain.

In this manual you learned  how to generate a Bitcoin Address using your
*private key*  or  even  any *public key*.  You also got to know how the
entire  algorithm works and  what  cryptographic functions are required.

You already know that an *address* consists  of  a string of letters and
numbers,  which is in fact an encoded *base58check* version of a *public
key* `160-bit` hash.  Just like you would ask others to send an email to
your  email  address, you  can ask them to send Bitcoins to your Bitcoin
Address.

The entire repository with the code and tests is available as module:
`BitcoinAddress.Primary`

```elixir
defmodule BitcoinAddress.Primary do
  @moduledoc false

  @dir_keypair ".keys/keys"
  @checksum_length 4
  @alphabet "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  @length String.length(@alphabet)
  @version_bytes %{
    main: <<0x00>>,
    test: <<0x6F>>
  }

  def write do
    keys = keypair()
    public_key  = keys |> elem(0)
    private_key = keys |> elem(1)
    with file_path = @dir_keypair,
      :ok <- File.write(file_path, "#{[private_key, public_key] |> Enum.join(", ")}") do
        %{"dir": file_path, "pri": private_key, "pub": public_key}
      else
        {:error, error} -> :file.format_error(error)
      end
  end

  def read do
    private_key = get_private_key()
    public_key  = get_public_key()
    %{"dir": @dir_keypair, "pri": private_key, "pub": public_key}
  end

  def sign do
    private_key = get_private_key() |> Base.decode16 |> elem(1)
    signature = :crypto.sign(
      :ecdsa,
      :sha256,
      "message",
      [private_key, :secp256k1]
    )
    {:ok, signature}
  end

  def verify do
    public_key = get_public_key() |> Base.decode16 |> elem(1)
    signature = sign() |> elem(1)

    varify = :crypto.verify(
    :ecdsa,
    :sha256,
    "message",
    signature,
    [public_key, :secp256k1]
    )
    {:ok, varify}
  end

  def address do
    private_key
    |> KeyPair.to_public_key()
    |> hash_160()
    |> prepend_version_byte(network)
    |> Check.call()
    |> Encode.call()
  end

  def check do
    versioned_hash = prepend_version()

    versioned_hash
    |> sha256()
    |> sha256()
    |> checksum()
    |> append(versioned_hash)
  end

  def call(input, acc \\ "")
  def call(0, acc), do: acc

  def call(input, acc) when is_binary(input) do
    input
    |> :binary.decode_unsigned()
    |> call(acc)
    |> prepend_zeros(input)
  end

  def call(input, acc) do
    input
    |> div(@length)
    |> call(extended_hash(input, acc))
  end

  defp keypair do
    {public_key, private_key} =
      with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
        do: {Base.encode16(public_key), Base.encode16(private_key)}
    {public_key, private_key}
  end

  defp get_private_key do
    File.read(".keys/keys")
    |> Tuple.to_list
    |> List.delete(:ok)
    |> List.to_string
    |> String.split(",")
    |> List.first
  end

  defp get_public_key do
    File.read(".keys/keys")
    |> Tuple.to_list
    |> List.delete(:ok)
    |> List.to_string
    |> String.split(",")
    |> List.last
    |> String.trim
  end

  defp prepend_version do
    public_hash = to_public_hash()
    network = :main

    @version_bytes
    |> Map.get(network)
    |> Kernel.<>(public_hash)
  end

  defp to_public_key do
    {public_key, args} = :crypto.generate_key(:ecdh, :secp256k1, get_private_key())
    {public_key, args}
  end

  defp to_public_hash do
    public_key = to_public_key() |> elem(0)

    public_key
    |> hash(:sha256)
    |> hash(:ripemd160)
  end

  defp extended_hash(input, acc) do
    @alphabet
    |> String.at(rem(input, @length))
    |> append(acc)
  end

  defp prepend_zeros(acc, input) do
    input
    |> encode_zeros()
    |> append(acc)
  end

  defp encode_zeros(input) do
    input
    |> leading_zeros()
    |> duplicate_zeros()
  end

  defp leading_zeros(input) do
    input
    |> :binary.bin_to_list()
    |> Enum.find_index(&(&1 != 0))
  end

  defp duplicate_zeros(count) do
    @alphabet
    |> String.first()
    |> String.duplicate(count)
  end

  defp hash(data, algorithm), do: :crypto.hash(algorithm, data)
  defp sha256(data), do: :crypto.hash(:sha256, data)
  defp checksum(<<checksum::bytes-size(@checksum_length), _::bits>>), do: checksum
  defp append(prefix, postfix), do: prefix <> postfix
end
```

### 15 May 2018 by Oleg G.Kapranov

[1]:  https://en.bitcoin.it/wiki/Address
[2]:  https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses
[3]:  https://blog.lelonek.me/how-to-calculate-bitcoin-address-in-elixir-68939af4f0e9
[4]:  https://github.com/KamilLelonek/ex_wallet
[5]:  https://github.com/ntrepid8/ex_crypto
[6]:  https://www.djm.org.uk/posts/cryptographic-hash-functions-elixir-generating-hex-digests-md5-sha1-sha2/
[7]:  http://www.petecorey.com/blog/tags#bitcoin
[8]:  http://www.petecorey.com/blog/tags#elixir
[9]:  https://github.com/pcorey/hello_bitcoin_node
[10]: https://github.com/pcorey/hello_blockchain
[11]: https://github.com/pcorey/hello_bitcoin
[12]: https://github.com/pcorey/bitcoin_network
