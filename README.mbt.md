# f4ah6o/calver

Calendar Versioning (CalVer) parser and comparator for MoonBit.

## Usage

```mbt test
let v = parse("2026.01.1-alpha.1+build.5")
inspect(v.to_string(), content="2026.01.1-alpha.1+build.5")
```

```mbt test
let a = parse("2026.01.1-alpha")
let b = parse("2026.01.1")
assert_true(a.compare(b) < 0)
```
