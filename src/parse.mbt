///|
/// Parse a Calver string with the default scheme.
pub fn parse(input : String) -> Calver raise CalverError {
  parse_with_scheme(input, default_scheme)
}

///|
/// Parse a Calver string with a scheme pattern.
pub fn parse_with_scheme(
  input : String,
  scheme : String,
) -> Calver raise CalverError {
  let (core, build_part) = split_once(input, "+")
  let core_result : Result[(Int, Int?, Int?, Int?, Int?), CalverError] = try? parse_core_with_scheme_checked(
    core, scheme,
  )
  let (year, month, week, day, micro, pre_part) = match core_result {
    Ok((y, m, w, d, mi)) => (y, m, w, d, mi, None)
    Err(_) => {
      let (base, pre_part) = split_once(core, "-")
      let (y, m, w, d, mi) = parse_core_with_scheme_checked(base, scheme)
      (y, m, w, d, mi, pre_part)
    }
  }
  let pre = match pre_part {
    None => []
    Some(value) => parse_prerelease(value)
  }
  let build = match build_part {
    None => []
    Some(value) => parse_build(value)
  }
  { scheme, year, month, week, day, micro, pre, build }
}

///|
pub fn try_parse(input : String) -> Result[Calver, CalverError] {
  try? parse(input)
}

///|
pub fn try_parse_with_scheme(
  input : String,
  scheme : String,
) -> Result[Calver, CalverError] {
  try? parse_with_scheme(input, scheme)
}

///|
fn parse_core_with_scheme_checked(
  value : String,
  scheme : String,
) -> (Int, Int?, Int?, Int?, Int?) raise CalverError {
  let (year, month, week, day, micro, consumed) = parse_core_with_scheme(
    value, scheme,
  )
  if consumed != value.length() {
    raise CalverError::InvalidFormat("expected scheme: \{scheme}")
  }
  (year, month, week, day, micro)
}

///|
fn parse_prerelease(value : String) -> Array[PreId] raise CalverError {
  let parts = split_to_strings(value, ".")
  parts.map(parse_prerelease_ident)
}

///|
fn parse_build(value : String) -> Array[String] raise CalverError {
  let parts = split_to_strings(value, ".")
  parts.map(parse_build_ident)
}

///|
fn parse_prerelease_ident(value : String) -> PreId raise CalverError {
  ensure_identifier(value, label="prerelease")
  if all_digits(value) {
    if value.length() > 1 && value[0] == '0' {
      raise CalverError::LeadingZero(value)
    }
    PreId::Num(parse_int(value, label="prerelease"))
  } else {
    PreId::Str(value)
  }
}

///|
fn all_digits(value : String) -> Bool {
  for c in value {
    if !(c is ('0'..='9')) {
      return false
    }
  }
  true
}

///|
fn parse_build_ident(value : String) -> String raise CalverError {
  ensure_identifier(value, label="build")
  value
}

///|
fn parse_int(value : String, label~ : String) -> Int raise CalverError {
  @strconv.parse_int(value, base=10) catch {
    _ => raise CalverError::InvalidNumber(label)
  }
}

///|
fn ensure_identifier(value : String, label~ : String) -> Unit raise CalverError {
  if value is "" {
    raise CalverError::InvalidIdentifier("\{label}: empty")
  }
  for c in value {
    if !is_identifier_char(c) {
      raise CalverError::InvalidIdentifier("\{label}: \{value}")
    }
  }
}

///|
fn is_identifier_char(c : Char) -> Bool {
  c is ('0'..='9') || c is ('a'..='z') || c is ('A'..='Z') || c == '-'
}

///|
fn split_to_strings(value : String, sep : String) -> Array[String] {
  value.split(sep).map(part => part.to_string()).to_array()
}

///|
fn split_once(
  value : String,
  sep : String,
) -> (String, String?) raise CalverError {
  match value.find(sep) {
    None => (value, None)
    Some(idx) => {
      let left = value[:idx] catch {
          _ => raise CalverError::InvalidFormat("invalid delimiter boundary")
        }
      let right = value[idx + sep.length():] catch {
          _ => raise CalverError::InvalidFormat("invalid delimiter boundary")
        }
      (left.to_string(), Some(right.to_string()))
    }
  }
}
