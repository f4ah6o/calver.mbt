///|
/// Calendar Versioning (CalVer) value.
pub(all) struct Calver {
  scheme : String
  year : Int
  month : Int?
  week : Int?
  day : Int?
  micro : Int?
  pre : Array[PreId]
  build : Array[String]
} derive(Show, Eq, ToJson)

///|
/// Pre-release identifier.
pub(all) enum PreId {
  Num(Int)
  Str(String)
} derive(Show, Eq, ToJson)

///|
pub let default_scheme : String = "YYYY.MM.MICRO"

///|
pub fn Calver::scheme(self : Calver) -> String {
  self.scheme
}

///|
pub fn Calver::with_scheme(
  scheme : String,
  year : Int,
  month? : Int,
  week? : Int,
  day? : Int,
  micro? : Int,
) -> Calver {
  { scheme, year, month, week, day, micro, pre: [], build: [] }
}

///|
/// Errors raised while parsing a Calver string.
pub suberror CalverError {
  InvalidFormat(String)
  InvalidNumber(String)
  LeadingZero(String)
  InvalidIdentifier(String)
  InvalidScheme(String)
} derive(Show, Eq)

///|
pub fn Calver::new(year : Int, month : Int, micro : Int) -> Calver {
  Calver::{
    scheme: default_scheme,
    year,
    month: Some(month),
    week: None,
    day: None,
    micro: Some(micro),
    pre: [],
    build: [],
  }
}

///|
pub fn Calver::with_prerelease(
  year : Int,
  month : Int,
  micro : Int,
  label : String,
  number : Int,
) -> Calver {
  Calver::{
    scheme: default_scheme,
    year,
    month: Some(month),
    week: None,
    day: None,
    micro: Some(micro),
    pre: [PreId::Str(label), PreId::Num(number)],
    build: [],
  }
}

///|
pub fn Calver::strip_build(self : Calver) -> Calver {
  Calver::{
    scheme: self.scheme,
    year: self.year,
    month: self.month,
    week: self.week,
    day: self.day,
    micro: self.micro,
    pre: self.pre,
    build: [],
  }
}

///|
pub fn Calver::to_string(self : Calver) -> String {
  let base = try! format_core_with_scheme(
    self.scheme,
    self.year,
    self.month,
    self.week,
    self.day,
    self.micro,
  )
  let pre = if self.pre.is_empty() {
    ""
  } else {
    "-" + self.pre.map(pre_id_to_string).join(".")
  }
  let build = if self.build.is_empty() {
    ""
  } else {
    "+" + self.build.join(".")
  }
  base + pre + build
}

///|
pub fn Calver::is_prerelease(self : Calver) -> Bool {
  !self.pre.is_empty()
}

///|
/// Compare versions by Calver precedence rules (build metadata ignored).
pub fn Calver::compare(self : Calver, other : Calver) -> Int {
  if self.scheme != other.scheme {
    return compare_string(self.scheme, other.scheme)
  }
  let core_cmp = compare_core_with_scheme(self.scheme, self, other)
  if core_cmp != 0 {
    core_cmp
  } else {
    compare_prerelease(self.pre, other.pre)
  }
}

///|
fn compare_int(a : Int, b : Int) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn compare_string(a : String, b : String) -> Int {
  let a_chars = a.iter().to_array()
  let b_chars = b.iter().to_array()
  let len = if a_chars.length() < b_chars.length() {
    a_chars.length()
  } else {
    b_chars.length()
  }
  for i = 0, result = 0; i < len && result == 0; {
    let cmp = compare_char(a_chars[i], b_chars[i])
    continue i + 1, cmp
  } else {
    if result != 0 {
      result
    } else {
      compare_int(a_chars.length(), b_chars.length())
    }
  }
}

///|
fn compare_char(a : Char, b : Char) -> Int {
  if a < b {
    -1
  } else if a > b {
    1
  } else {
    0
  }
}

///|
fn compare_pre_id(a : PreId, b : PreId) -> Int {
  match (a, b) {
    (Num(x), Num(y)) => compare_int(x, y)
    (Num(_), Str(_)) => -1
    (Str(_), Num(_)) => 1
    (Str(x), Str(y)) => compare_string(x, y)
  }
}

///|
fn compare_prerelease(a : Array[PreId], b : Array[PreId]) -> Int {
  if a.is_empty() && b.is_empty() {
    0
  } else if a.is_empty() {
    1
  } else if b.is_empty() {
    -1
  } else {
    let len = if a.length() < b.length() { a.length() } else { b.length() }
    for i = 0, result = 0; i < len && result == 0; {
      let cmp = compare_pre_id(a[i], b[i])
      continue i + 1, cmp
    } else {
      if result != 0 {
        result
      } else {
        compare_int(a.length(), b.length())
      }
    }
  }
}

///|
fn pre_id_to_string(id : PreId) -> String {
  match id {
    Num(value) => value.to_string()
    Str(value) => value
  }
}
