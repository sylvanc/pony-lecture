use "collections"
use "time"
use "options"
use "term"

actor PingPong
  let _out: OutStream
  var _pings: U64 = 0
  var _pongs: U64 = 0

  new create(out: OutStream) =>
    _out = out

  be apply(players: Array[PingPong] val, pings: U64, seed: U64, print: Bool) =>
    let len = players.size()
    var random = seed

    for i in Range(0, pings) do
      try players(random % len).ping(this, print) end
      random = random.hash()
    end

  be ping(from: PingPong, print: Bool) =>
    _pings = _pings + 1
    from.pong(print)
    if print then _out.write(ANSI.green() + "Ping... ") end

  be pong(print: Bool) =>
    _pongs = _pongs + 1
    if print then _out.write(ANSI.red() + "Pong! ") end

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

    let players_iso = recover Array[PingPong](actors) end

    for i in Range(0, actors) do
      players_iso.push(PingPong(env.out))
    end

    let players = consume val players_iso
    var random = Time.nanos().hash()

    for player in players.values() do
      player(players, pings, random, print)
      random = random.hash()
    end
