# Myhtmlex

Bindings for lexborisov's [myhtml](https://github.com/lexborisov/myhtml).

* Available as a hex package: `{:myhtmlex, "~> 0.2.0"}`
* [Documentation](https://hexdocs.pm/myhtmlex/Myhtmlex.html)

## Example

    iex> Myhtmlex.decode("<h1>Hello world</h1>")
    {"html", [], [{"head", [], []}, {"body", [], [{"h1", [], ["Hello world"]}]}]}

  Benchmark results (Nif calling mode) on various file sizes on a 2,5Ghz Core i7:

      Settings:
        duration:      1.0 s

      ## FileSizesBench
      [15:28:42] 1/3: github_trending_js.html 341k
      [15:28:46] 2/3: w3c_html5.html 131k
      [15:28:48] 3/3: wikipedia_hyperlink.html 97k

      Finished in 7.52 seconds

      ## FileSizesBench
      benchmark name                iterations   average time
      wikipedia_hyperlink.html 97k        1000   1385.86 µs/op
      w3c_html5.html 131k                 1000   2179.30 µs/op
      github_trending_js.html 341k         500   5686.21 µs/op

## Configuration

The module you are calling into is always `Myhtmlex` and depending on your application configuration,
it chooses between the underlying implementations `Myhtmlex.Safe` (default) and `Myhtmlex.Nif`.

Erlang interoperability is a tricky mine-field.
You can call into C directly using native implemented functions (Nif). But this comes with the risk,
that if anything goes wrong within the C implementation, your whole VM will crash.
No more supervisor cushions for here on, just violent crashes.

That is why the default mode of operation keeps your VM safe and happy.
If you need ultimate parsing speed, or you can simply tolerate VM-level crashes, read on.

### Call into C-Node (default)

This is the default mode of operation.
If your application cannot tolerate VM-level crashes, this option allows you to gain the best of both worlds.
The added overhead is client/server communications, and a worker OS-process that runs next to your VM under VM supervision.

You do not have to do anything to start the worker process, everything is taken care of within the library.
If you are not running in distributed mode, your VM will automatically be assigned a `sname`.

The worker OS-process stays alive as long as it is under VM-supervision. If your VM goes down, the OS-process will die by itself.
If the worker OS-process dies for some reason, your VM stays unaffected and will attempt to restart it seamlessly.

### Call into Nif

If your application is aiming for ultimate parsing speed, and in the worst case can tolerate VM-level crashes, you can call directly into the Nif.

1. Require myhtmlex without runtime

    in your `mix.exs`

        def deps do
          [
            {:myhtmlex, ">= 0.0.0", runtime: false}
          ]
        end

2. Configure the mode to `Myhtmlex.Nif`

    e.g. in `config/config.exs`

        config :myhtmlex, mode: Myhtmlex.Nif

3. Bonus: You can [open up in-memory references to parsed trees](https://hexdocs.pm/myhtmlex/Myhtmlex.html#open/1), without parsing + mapping erlang terms in one go

## Contribution / Bug Reports

* Please make sure you do `git submodule update` after a checkout/pull
* If you have problems building the project, please consider adding a Dockerfile to `build-tests/` to replicate the build error
* The project aims to be fully tested

## Roadmap

The exposed functions on `Myhtmlex` are not subject to change.
This project is under active development.

* [ ] Expose node-retrieval functions
* [x] Parse a HTML-document into a tree
* [x] Investigate safety and calling options
  * [x] Call as dirty-nif
  * [x] Call as C-Node (check branch `c-node`)

