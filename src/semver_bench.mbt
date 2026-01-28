///|
test "parse benchmark" (b : @bench.T) {
  b.bench(fn() { ignore(try! parse("1.2.3-alpha.1+build.5")) })
}

///|
test "compare benchmark" (b : @bench.T) {
  let a = try! parse("1.2.3-alpha.1+build.5")
  let c = try! parse("1.2.3")
  b.bench(fn() { ignore(a.compare(c)) })
}
