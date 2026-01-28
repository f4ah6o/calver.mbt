# mizchi/semver

Semantic Versioning (SemVer 2.0.0) parser and comparator for MoonBit.

## Usage

```mbt test
let v = parse("1.2.3-alpha.1+build.5")
inspect(v.to_string(), content="1.2.3-alpha.1+build.5")
```

```mbt test
let a = parse("1.0.0-alpha")
let b = parse("1.0.0")
assert_true(a.compare(b) < 0)
```
