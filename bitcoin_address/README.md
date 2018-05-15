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
defmodule BitcoinAddress do
  @moduledoc false

  def keypair do
    with {public_key, private_key} <- :crypto.generate_key(:ecdh, :secp256k1),
      do: {Base.encode16(public_key), Base.encode16(private_key)}
  end
end

BitcoinAddress.keypair
#=> {
#=>   "04BC2BB248E2EFCD36A4F88050137FB531476F937D36A3351425453F8CB12DDDC3DFBB623EA414C2C9788AB2329401C3FCE0725F57154B30AD85C862A72E8882F2",
#=>   "2BA9695DE3EF229E23A5532C673C0A2AB2E213044572EE0AC6F0556499669D1A"
#=> }
```

You  don't  need  anything else to create an `ECDH`-compliant keys in a
convenient to use `Base16` (hexadecimal) format.

If you want to store such keys, you can persist them on a disk or use a
special kind of "database" called wallet.  It's a place, either digital
or  physical,  which,  in  its basic form, keeps your keys secretly. It
doesn't  require  any connection  to  the network or a reference to the
Blockchain.

```elixir
defmodule BitcoinAddress do
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
BitcoinAddress.keypair |> elem(1)
BitcoinAddress.write
#=> {
#=>   ".keys/key",
#=>   "8872CFBC3BFFEE5D190BB880C14D5528262982B4D57009061F12E3F60727DD92"
#=> }
```

### 15 May 2018 by Oleg G.Kapranov

[1]: https://en.bitcoin.it/wiki/Address
[2]: https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses
[3]: https://blog.lelonek.me/how-to-calculate-bitcoin-address-in-elixir-68939af4f0e9
