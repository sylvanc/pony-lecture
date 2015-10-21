use "collections"
use "time"
use "options"
use "term"

actor PingPong
  let _out: OutStream
  let _partner: PingPong
  let _print: Bool
  var _pings: U64 = 0
  var _pongs: U64 = 0

  new create(pings: U64, print: Bool, out: OutStream) =>
    _out = out
    _partner = PingPong.partner(this, pings, print, out)
    _print = print

    for i in Range(0, pings) do
      _partner.ping()
    end

  new partner(that: PingPong, pings: U64, print: Bool, out: OutStream) =>
    _out = out
    _partner = that
    _print = print

    for i in Range(0, pings) do
      _partner.ping()
    end

  be ping() =>
    _pings = _pings + 1
    _partner.pong()
    if _print then _out.write(ANSI.green() + "Ping... " + ANSI.reset()) end

  be pong() =>
    _pongs = _pongs + 1
    if _print then _out.write(ANSI.red() + "Pong! " + ANSI.reset()) end

actor Main
  new create(env: Env) =>
    var actors = U64(2)
    var pings = U64(3)
    var print = false

    let options = Options(env) +
      ("actors", "a", I64Argument) +
      ("pings", "p", I64Argument) +
      ("print", "", None)

    for opt in options do
      match opt
      | ("actors", let arg: I64) => actors = arg.u64()
      | ("pings", let arg: I64) => pings = arg.u64()
      | ("print", None) => print = true
      end
    end

    for i in Range(0, actors / 2) do
      PingPong(pings, print, env.out)
    end
