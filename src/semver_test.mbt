///|
test "parse basic" {
  let v = parse("2026.01.1")
  inspect(v.to_string(), content="2026.1.1")
  assert_true(!v.is_prerelease())
}

///|
test "parse prerelease build" {
  let v = parse("2026.01.1-alpha.1+build.5")
  inspect(v.to_string(), content="2026.1.1-alpha.1+build.5")
  assert_true(v.is_prerelease())
}

///|
test "invalid leading zero" {
  let result : Result[Calver, CalverError] = try? parse("2026.01.01")
  inspect(result, content="Err(LeadingZero(\"micro: 01\"))")
}

///|
test "compare prerelease precedence" {
  let a = parse("2026.01.1-alpha")
  let b = parse("2026.01.1-alpha.1")
  let c = parse("2026.01.1-alpha.beta")
  let d = parse("2026.01.1-beta")
  let e = parse("2026.01.1-beta.2")
  let f = parse("2026.01.1-beta.11")
  let g = parse("2026.01.1-rc.1")
  let h = parse("2026.01.1")
  assert_true(a.compare(b) < 0)
  assert_true(b.compare(c) < 0)
  assert_true(c.compare(d) < 0)
  assert_true(d.compare(e) < 0)
  assert_true(e.compare(f) < 0)
  assert_true(f.compare(g) < 0)
  assert_true(g.compare(h) < 0)
}

///|
test "compare numeric vs string prerelease" {
  let a = parse("2026.01.1-1")
  let b = parse("2026.01.1-alpha")
  assert_true(a.compare(b) < 0)
}
