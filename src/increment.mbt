///|
priv enum ReleaseType {
  Pre
  Prerelease
  Release
}

///|
fn parse_release_type(release : String) -> ReleaseType? {
  match release {
    "pre" => Some(ReleaseType::Pre)
    "prerelease" => Some(ReleaseType::Prerelease)
    "release" => Some(ReleaseType::Release)
    _ => None
  }
}

///|
fn normalize_identifier_base(base : Int) -> Int {
  if base < 0 {
    0
  } else {
    base
  }
}

///|
fn parse_identifier_opt(identifier : String?) -> PreId? {
  match identifier {
    None => None
    Some(value) => {
      let result : Result[PreId, CalverError] = try? parse_prerelease_ident(
        value,
      )
      match result {
        Ok(id) => Some(id)
        Err(_) => None
      }
    }
  }
}

///|
fn inc_pre_ids(
  current : Array[PreId],
  identifier : PreId?,
  base : Int,
) -> Array[PreId] {
  let next = current.copy()
  let mut last_numeric : Int? = None
  for i, id in next {
    if id is Num(_) {
      last_numeric = Some(i)
    }
  }
  match last_numeric {
    Some(i) =>
      match next[i] {
        Num(value) => next[i] = Num(value + 1)
        _ => ()
      }
    None => next.push(Num(base))
  }
  match identifier {
    None => next
    Some(id) => {
      let reset = [id, Num(base)]
      match next.get(0) {
        Some(first) if first == id =>
          if next.length() < 2 {
            reset
          } else {
            match next[1] {
              Num(_) => next
              _ => reset
            }
          }
        _ => reset
      }
    }
  }
}

///|
fn inc_calver(
  version : Calver,
  release : ReleaseType,
  identifier : PreId?,
  identifier_base : Int,
) -> Calver {
  let base = normalize_identifier_base(identifier_base)
  let mut pre : Array[PreId] = []
  match release {
    ReleaseType::Release => pre = []
    ReleaseType::Pre => pre = inc_pre_ids(version.pre, identifier, base)
    ReleaseType::Prerelease =>
      if version.pre.is_empty() {
        pre = inc_pre_ids([], identifier, base)
      } else {
        pre = inc_pre_ids(version.pre, identifier, base)
      }
  }
  Calver::{
    scheme: version.scheme,
    year: version.year,
    month: version.month,
    week: version.week,
    day: version.day,
    micro: version.micro,
    pre,
    build: [],
  }
}

///|
pub fn Calver::inc(
  self : Calver,
  release : String,
  identifier? : String,
  identifier_base? : Int = 0,
) -> Calver? {
  inc_calver_option(self, release, identifier, identifier_base)
}

///|
pub fn inc(
  version : String,
  release : String,
  identifier? : String,
  identifier_base? : Int = 0,
) -> String? {
  match try_parse(version) {
    Ok(value) =>
      match inc_calver_option(value, release, identifier, identifier_base) {
        Some(next) => Some(next.to_string())
        None => None
      }
    Err(_) => None
  }
}

///|
fn inc_calver_option(
  version : Calver,
  release : String,
  identifier : String?,
  identifier_base : Int,
) -> Calver? {
  match parse_release_type(release) {
    None => None
    Some(release_type) =>
      match parse_identifier_opt(identifier) {
        None =>
          if identifier is None {
            Some(inc_calver(version, release_type, None, identifier_base))
          } else {
            None
          }
        Some(id) =>
          Some(inc_calver(version, release_type, Some(id), identifier_base))
      }
  }
}
