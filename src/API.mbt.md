# API Documentation

Executable doc tests for calver parsing and comparison.

## parse

```mbt check
///|
test {
  inspect(parse("2026.01.1").to_string(), content="2026.1.1")
  inspect(
    parse("2026.01.1-alpha.1+build.5").to_string(),
    content="2026.1.1-alpha.1+build.5",
  )
}
```

## compare

```mbt check
///|
test {
  let a = parse("2026.01.1-rc.1")
  let b = parse("2026.01.1")
  assert_true(a.compare(b) < 0)
}
```

## inc

```mbt check
///|
test {
  inspect(inc("2026.01.1", "release"), content="Some(\"2026.1.1\")")
  inspect(
    inc("2026.01.1", "prerelease", identifier="beta"),
    content="Some(\"2026.1.1-beta.0\")",
  )
}
```
