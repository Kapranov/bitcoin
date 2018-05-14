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
║          On May 15th 2018 Bitcoin price reached $17032,78           ║
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
I'm using Exlixir `1.6.5` here. If you are using `1.3` or lower remember
to update your `applications` function too.

Now open up `lib/loss_tracker/application.ex` and tell our application
to start Plug and integrate with Cowboy.

```elixir
defmodule LossTracker.Application do
  @moduledoc false

  alias LossTracker.Router

  use Application

  def start(_type, _args) do
    children = [
      Plug.Adapters.Cowboy.child_spec(
        scheme: :http,
        plug: Router,
        options: [port: 4001]
      )
    ]

    opts = [strategy: :one_for_one, name: LossTracker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```
Here we tell Plug to integrate with Cowboy and pass all incoming traffic
to `LossTracker.Router`.  All  requests  will be delivered to the router
as  `Conn`  structs  we  talked  about  earlier. We have not written our
router yet so we’ll look at it next.

```elixir
defmodule LossTracker.Router do
  use Plug.Router

  alias LossTracker.PageProcessor

  plug :match
  plug :dispatch

  get "/about" do
    send_resp(conn, 200, "This is a demo site")
  end

  match _ do
    PageProcessor.call(conn, PageProcessor.init([]))
  end
end
```

The  router is the first plug  that our conn struct will encounter. This
is also where we get to see the first example of how easily plugs can be
used and chained together. We tell the router to pipe our `conn` through
two plugs: `match` and `dispatch`.  These two plugs are provided by Plug
and  take care of matching  the request's path and dispatching it to the
correct route handler. If you wanted to modify this behaviour  you could
write your own plugs and include them in there too.

Within the router, we specify two route handlers. The first one is an
example of how the Plug router works - it matches GET requests sent to
`/about`. Whenever a user navigates to that URL the `conn` struct will
be passed to `send_resp` which, in turn, will set the response code to
200 and put a short string in the response's body using a special
`send_resp` function. It is special because instead of simply returning
a slightly modified `conn`, like most plugs do, it immediately sends the
response back to the caller.

The second route handler matches all other URLs and will pass the conn
to the `PageProcessor` *module plug* which we are going to write next.

```elixir
defmodule LossTracker.PageProcessor do
  import Plug.Conn

  alias LossTracker.BitcoinAPI

  def init(options), do: options

  def call(conn, _opts) do
    conn
    |> calculate_loss()
    |> build_page()
  end

  defp calculate_loss(conn) do
    current_price = BitcoinAPI.current_price()
    current_loss = BitcoinAPI.current_loss(current_price)

    conn
    |> assign(:current_price, current_price)
    |> assign(:current_loss, current_loss)
  end

  defp build_page(conn) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, render_page(conn))
  end

  defp render_page(conn) do
    """
    <!DOCTYPE html>
    <html>
      <head>
        <title>Bitcoin loss tracker</title>
        <style>
          html {
            background-color: #252839;
            color: #f2b632;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
            font-size: 24px;
            text-align: center;
          }
          div {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            padding: 3rem;
            border: 6px solid #f2b632;
            border-radius: 6px;
          }
          p {
          margin: 1rem 0;
          }
          p:first-of-type {
            font-size: 0.8rem;
            line-height: 1rem;
          }
          p:last-of-type {
            font-size: 1.4rem;
          }
          .percentage {
            font-weight: 700;
            font-size: 1.8rem;
          }
        </style>
      </head>
      <body>
        <div>
          <p>On May 15th 2018 Bitcoin price reached $#{BitcoinAPI.max_price()}</p>
          <p>Current Bitcoin value is $#{conn.assigns[:current_price]}</p>
          <p>You could have lost <span class="percentage">#{:erlang.float_to_binary(conn.assigns[:current_loss], [decimals: 1])}%</span> of your money!</p>
        </div>
      </body>
    </html>
    """
  end
end
```

The `PageProcessor` here is where the  response  is  put  together.  Its
`call` function  accepts  a  `conn` and modifies it in a number of ways.
First, it  passes the  `conn` to  `calculate_loss` where  it obtains the
current  price and current  maximum  possible loss from the `BitcoinAPI`
module and puts them  in the  `conn`  to be used later. `Conn`  structs,
apart from carrying information about requests  and  responses, can also
carry  other  arbitrary  data.  This  is exactly what we tell our `conn`
to do here by calling `assign`.

The `conn` is then passed to `build_page` where it is assigned a content
type of `text/html` and used  to send a response back to the caller. The
response is given a 200 status code and a body.

The  body  of  the  response  is  HTML  returned  from the `render_page`
function.  It  prints  the current  price  of  Bitcoin and  the  maximum
possible loss on the page and applies some styling to it.

Finally, the `BitcoinAPI` module. This is the only part  of our app that
doesn't use plugs.  It  is a simple  interface  for fetching the current
Bitcoin price from one of the Bitcoin trading platforms which provides a
free API.

```elixir
defmodule LossTracker.BitcoinAPI do
  @moduledoc false

  @max_price 17_032.78
  @api_url "https://www.bitstamp.net/api/ticker/"

  def current_loss(current_price) do
    (@max_price - current_price) / @max_price * 100
  end

  def current_price do
    case HTTPoison.get(@api_url) do
      {:ok, response} ->
        response.body
        |> Poison.decode!
        |> Map.get("last")
        |> String.to_float
      {:error, _} ->
        nil
    end
  end

  def max_price do
    @max_price
  end
end
```

This is it!  Start the server with `mix run --no-halt` or  `iex -S mix`
if  you  want  to  play  around  in  the  IEx console) and navigate to:
`localhost:4001`.  You should see something similar to the image below.

### Summary

In this short demo,  we  have  had a look at what Plug library is, what
tools  it provides and how they can be used to put together a basic web
application. We have seen that Plug gives us everything needed to build
a simple website, even without using Phoenix.  Of course, the ecosystem
is not perfect and is devoid of numerous  Phoenix's  eatures.  This  is
because  Plug  is not meant to be a web framework. Instead, it is a web
server interface we can use to  build other things on and it is exactly
what Phoenix does.

As  an  engineer,  I  believe  it  is  important to keep  improving our
understanding of technologies underpinning the tools we work with. Even
if  you  are  not going to build directly on Plug, knowing how it works
will help you leverage its power 1when working with Phoenix. After all,
Phoenix is nothing else but a giant plug.

Hubert Pompecki `hpompecki@gmail.com`

**TODO: Add description**

```sh
mix test

./run_test.sh

mix run --no-halt
iex -S mix
```

![Plugs Demystified](./bitcoin.jpg)

### 15 May 2018 by Oleg G.Kapranov

[1]: https://www.pompecki.com/post/plugs-demystified/
[2]: https://hexdocs.pm/plug/readme.html
