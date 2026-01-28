# mizchi/semver

Semantic Versioning (SemVer 2.0.0) parser and comparator for MoonBit.

## Usage

```moonbit
let v = parse("1.2.3-alpha.1+build.5")
println(v.to_string())
```

```moonbit
let a = parse("1.0.0-alpha")
let b = parse("1.0.0")
assert_true(a.compare(b) < 0)
```
