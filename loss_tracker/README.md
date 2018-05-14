# LossTracker

*Plugs Demystified*

Understand Plug and build a simple website using Elixir.

## Is Phoenix the only way?

When I first heard about Elixir what really piqued my  interest about it
was Phoenix's speed.  Coming  from  a Rails  background, sub-millisecond
response times some of my colleagues talked about felt almost surreal. I
eventually wanted to see what  it was all about myself and that is how I
started reading Elixir docs.

I  presume  I  am  not  the  only  one who reached for Elixir because of
Phoenix. It is the default web framework  most  of  us  reach for in the
Elixir world. This fact, however, leads to a somewhat academic  question
- is  it  possible  to  build a simple web service without using Phoenix
and, if so, how hard would it be?

### Meet Plug

One of the most  obvious  alternatives  is [Plug][2].  Plug is a library
providing a uniform interface for talking to web servers in the ErlangVM
and an easy way to build composable modules (aka plugs) which can be put
together to process web requests.

The two key parts of the Plug ecosystem are the `Conn` struct  and plugs
which manipulate it.  The `Conn`  struct is what represents a full  HTTP
request/response cycle. It includes  request and response  bodies, query
params,  cookies,  IP  data  and a myriad of other things  which you can
inspect  and  manipulate.  Plugs,  on  the  other  hand, are  modules or
functions which  take  a  `Conn` and return a modified version  of it. A
plug  can  modify  a  `Conn` in a number of ways such us redirect  to an
HTTPS  version  of  a  URL,  verify  security headers, log the  incoming
request, or set a response code and a body.

It  is  an  easy and efficient system - build some plugs and  chain them
together to process an incoming `Conn`.

```sh
          ╔══════════════════╗            ╔══════════════════╗
          ║       Plug 1     ║            ║       Plug 2     ║
          ╟──────────────────╢            ╟──────────────────╢
╔══════╗  ║                  ║  ╔══════╗  ║                  ║  ╔══════╗
║ Conn ╟─>║  Accepts a conn, ╟─>║ Conn ╟─>║  Accepts a conn, ╟─>║ Conn ║
╚══════╝  ║    returns a     ║  ╚══════╝  ║     returns a    ║  ╚══════╝
          ║ modified version ║            ║ modified version ║
          ║      version     ║            ║                  ║
          ╚══════════════════╝            ╚══════════════════╝
```

Plug  is, in fact, the foundation on which Phoenix  is built - Phoenix's
controllers are just plugs!  Let's put Phoenix aside for  now though and
see how easy it is to use Plug directly.

### The aim

We are going  to build a simple  website displaying the current price of
Bitcoin  and calculating  the  maximum  possible  loss  one  could  make
assuming they  invested in Bitcoin  on the day it reached its peak price
(at the time of writing the highest Bitcoin price ever was $17,032.63 on
15/05/2018). Instead of instinctively reaching  for  Phoenix, we'll only
use Plug and see how easy the process is. The sketch below  is  a simple
illustration of what we aim to achieve.

```sh
╔═════════════════════════════════════════════════════════════════════╗
║                                                                     ║
║          On May 15th 2018 Bitcoin price reached $17032,775          ║
║                 Current Bitcoin value is $8425.23                   ║
║                                                                     ║
║              YOU COULD HAVE LOST -1.45% OF YOUR MONEY!              ║
║                                                                     ║
╚═════════════════════════════════════════════════════════════════════╝
```

It is a fairly simple project which will serve us well as an example.

### Code

Let's start by creating  a new `mix` project. We'll use the `--sup` flag
to include a supervision tree. `mix new loss_tracker --sup`

We  need  to  add  some  dependencies  to the `mix.exs` file. Other than
including `plug` we will also add `cowboy` (the web server), `httpoison`
(making HTTP requests to be Bitcoin price server)  and `poison` (parsing
JSON).   Don't  forget  to  run  `mix  deps.get`  to  install  the   new
dependencies.

```elixir
defmodule LossTracker.MixProject do
  use Mix.Project

  # ...

  defp deps do
    [
      {:ex_doc, "~> 0.18.3", only: :dev, runtime: false},
      {:credo, "~> 0.9.2", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
      {:mix_test_watch, "~> 0.6", only: :dev, runtime: false},
      {:ex_unit_notifier, "~> 0.1.4", only: :test},
      {:cowboy, "~> 2.4.0"},
      {:plug, "~> 1.5.0"},
      {:httpoison, "~> 1.1.1"},
      {:poison, "~> 3.1.0"}
    ]
  end
end
```

**TODO: Add description**

```sh
mix test

./run_test.sh
```


### 15 May 2018 by Oleg G.Kapranov

[1]: https://www.pompecki.com/post/plugs-demystified/
[2]: https://hexdocs.pm/plug/readme.html
