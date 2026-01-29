///|
test "inc release" {
  inspect(inc("2026.01.1-rc.1", "release"), content="Some(\"2026.1.1\")")
}

///|
test "inc prerelease" {
  inspect(
    inc("2026.01.1", "prerelease", identifier="beta"),
    content="Some(\"2026.1.1-beta.0\")",
  )
  inspect(
    inc("2026.01.1-beta.2", "prerelease"),
    content="Some(\"2026.1.1-beta.3\")",
  )
  inspect(
    inc("2026.01.1-beta", "prerelease"),
    content="Some(\"2026.1.1-beta.0\")",
  )
}

///|
test "inc prerelease base" {
  inspect(
    inc("2026.01.1", "pre", identifier="alpha", identifier_base=1),
    content="Some(\"2026.1.1-alpha.1\")",
  )
}
