# Myhtmlex

Bindings for lexborisov's [myhtml](https://github.com/lexborisov/myhtml).

* Available as a hex package: `{:myhtmlex, "~> 0.1.0"}`
* [Documentation](https://hexdocs.pm/myhtmlex/Myhtmlex.html)

## Example

    iex> Myhtmlex.decode("<h1>Hello world</h1>")
    {"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Hello world"]}]}]}

## Thoughts

I need to a fast html-parsing library in Erlang/Elixir.
So falling back to c, and to myhtml especially, is a natural move.

But Erlang interoperability is a tricky mine-field.
This increase in parsing speed does not come for free.

The current implementation can be considered a proof-of-concept.
The myhtml code is called as a dirty-nif and executed **inside the Erlang-VM**.
Thus completely giving up the safety of the Erlang-VM. I am not saying that myhtml is unsafe, but
the slightest Segfault brings down the whole Erlang-VM.
So, I consider this mode of operation unsafe, and **not recommended for production use**.

The other option, that I have on my roadmap, is to call into a C-Node.
A separate OS-process that receives calls from erlang and returns to the calling process.

Another option is to call into a Port driver.
A separate OS-process that communicates via stdin/stdout.

So to recap, I want a **fast** and **safe** html-parsing library for Erlang/Elixir.

Not quite there, yet.

## Development

* Please make sure you do `git submodule update` after a checkout/pull

## Status

Currently under development.

* [x] Parse a HTML-document into a tree
* [ ] Expose node-retrieval functions
* [ ] Investigate safety and calling options
  * [x] Call as dirty-nif
  * [x] Call as C-Node (check branch `c-node`)
  * [ ] Call as Port driver

