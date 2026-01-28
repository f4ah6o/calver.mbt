///|
test "inc major minor patch" {
  inspect(inc("1.2.3", "major"), content="Some(\"2.0.0\")")
  inspect(inc("1.2.3", "minor"), content="Some(\"1.3.0\")")
  inspect(inc("1.2.3", "patch"), content="Some(\"1.2.4\")")
}

///|
test "inc drops prerelease on major minor patch" {
  inspect(inc("1.0.0-rc.1", "major"), content="Some(\"1.0.0\")")
  inspect(inc("1.2.0-beta.1", "minor"), content="Some(\"1.2.0\")")
  inspect(inc("1.2.3-beta.1", "patch"), content="Some(\"1.2.3\")")
}

///|
test "inc prerelease" {
  inspect(
    inc("1.2.3", "prerelease", identifier="beta"),
    content="Some(\"1.2.4-beta.0\")",
  )
  inspect(inc("1.2.3-beta.2", "prerelease"), content="Some(\"1.2.3-beta.3\")")
  inspect(inc("1.2.3-beta", "prerelease"), content="Some(\"1.2.3-beta.0\")")
}

///|
test "inc premajor preminor prepatch" {
  inspect(
    inc("1.2.3", "premajor", identifier="alpha"),
    content="Some(\"2.0.0-alpha.0\")",
  )
  inspect(
    inc("1.2.3", "preminor", identifier="alpha"),
    content="Some(\"1.3.0-alpha.0\")",
  )
  inspect(
    inc("1.2.3", "prepatch", identifier="alpha"),
    content="Some(\"1.2.4-alpha.0\")",
  )
}

///|
test "inc prerelease base" {
  inspect(
    inc("1.2.3", "preminor", identifier="alpha", identifier_base=1),
    content="Some(\"1.3.0-alpha.1\")",
  )
}

///|
test "inc release" {
  inspect(inc("1.2.3-beta.1", "release"), content="Some(\"1.2.3\")")
}
