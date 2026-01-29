# f4ah6o/calver

Calendar Versioning (CalVer) parser and comparator for MoonBit.

## Usage

```moonbit
let v = parse("2026.01.1-alpha.1+build.5")
println(v.to_string())
```

```moonbit
let a = parse("2026.01.1-alpha")
let b = parse("2026.01.1")
assert_true(a.compare(b) < 0)
```
