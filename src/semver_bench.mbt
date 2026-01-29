///|
test "parse benchmark" (b : @bench.T) {
  b.bench(fn() { ignore(try! parse("2026.01.1-alpha.1+build.5")) })
}

///|
test "compare benchmark" (b : @bench.T) {
  let a = try! parse("2026.01.1-alpha.1+build.5")
  let c = try! parse("2026.01.1")
  b.bench(fn() { ignore(a.compare(c)) })
}
