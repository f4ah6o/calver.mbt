///|
test "invalid core formats" {
  let cases = ["", "2026", "2026.01", "2026.01.1.1"]
  for s in cases {
    let result : Result[Calver, CalverError] = try? parse(s)
    match result {
      Err(CalverError::InvalidFormat(_)) => ()
      _ => fail("expected InvalidFormat")
    }
  }
}

///|
test "invalid prerelease/build empty segments" {
  let cases = [
    ("2026.01.1-", "prerelease: empty"),
    ("2026.01.1-alpha..1", "prerelease: empty"),
    ("2026.01.1-alpha.", "prerelease: empty"),
    ("2026.01.1+", "build: empty"),
    ("2026.01.1+build..1", "build: empty"),
    ("2026.01.1+build.", "build: empty"),
  ]
  for item in cases {
    let (s, expected) = item
    let result : Result[Calver, CalverError] = try? parse(s)
    match result {
      Err(CalverError::InvalidIdentifier(msg)) => assert_eq(msg, expected)
      _ => fail("expected InvalidIdentifier")
    }
  }
}

///|
test "invalid identifier characters" {
  let cases = [
    ("2026.01.1-alpha_", "prerelease: alpha_"),
    ("2026.01.1-α", "prerelease: α"),
    ("2026.01.1+build!", "build: build!"),
    ("2026.01.1+α", "build: α"),
  ]
  for item in cases {
    let (s, expected) = item
    let result : Result[Calver, CalverError] = try? parse(s)
    match result {
      Err(CalverError::InvalidIdentifier(msg)) => assert_eq(msg, expected)
      _ => fail("expected InvalidIdentifier")
    }
  }
}

///|
test "invalid scheme" {
  let cases = [
    "YYYY.0M.0D.0D", "YYYY.0M.0D.0W", "MM.YYYY.0D", "YYYY.0W.0D", "YYYY.0D", "YYYY0M0D",
    "YYYY.MM.MICRO.0D",
  ]
  for pattern in cases {
    let result : Result[Calver, CalverError] = try? parse_with_scheme(
      "2026.01.1", pattern,
    )
    match result {
      Err(CalverError::InvalidScheme(_)) => ()
      Err(CalverError::InvalidFormat(_)) => ()
      _ => ()
    }
  }
}

///|
test "leading zeros" {
  let cases = [("2026.01.01", "micro: 01"), ("2026.01.1-01", "01")]
  for item in cases {
    let (s, expected) = item
    let result : Result[Calver, CalverError] = try? parse(s)
    match result {
      Err(CalverError::LeadingZero(value)) => assert_eq(value, expected)
      _ => fail("expected LeadingZero")
    }
  }
}

///|
test "build metadata ignored in compare" {
  let a = parse("2026.01.1+1")
  let b = parse("2026.01.1+2")
  let c = parse("2026.01.1-alpha+1")
  let d = parse("2026.01.1-alpha+2")
  assert_eq(a.compare(b), 0)
  assert_eq(c.compare(d), 0)
}

///|
test "prerelease lexicographic and numeric ordering" {
  let a = parse("2026.01.1-alpha")
  let b = parse("2026.01.1-alpha.0")
  let c = parse("2026.01.1-alpha-1")
  let d = parse("2026.01.1-alpha.9")
  let e = parse("2026.01.1-alpha.10")
  let f = parse("2026.01.1-alpha.9a")
  let g = parse("2026.01.1-beta")
  assert_true(a.compare(b) < 0)
  assert_true(a.compare(c) < 0)
  assert_true(d.compare(e) < 0)
  assert_true(d.compare(f) < 0)
  assert_true(a.compare(g) < 0)
}

///|
test "scheme parsing" {
  let w = parse_with_scheme("26.1.3", "YY.MM.MICRO")
  inspect(w.to_string(), content="26.1.3")
  let x = parse_with_scheme("2026.01", "YYYY.0M")
  inspect(x.to_string(), content="2026.01")
  let y = parse_with_scheme("2026.01.1", "YYYY.MM.MICRO")
  inspect(y.to_string(), content="2026.1.1")
}
