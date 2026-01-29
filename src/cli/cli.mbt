///|
let usage_text : String =
  #|moonver <command> [args]
  #|
  #|Commands:
  #|  init [--release <version>] [--alpha <n>] [--beta <n>] [--rc <n>] [--force]
  #|  get <alpha|beta|rc|release> <version>
  #|  up <alpha|beta|rc|release|pre|prerelease> <version>
  #|  scheme <pattern> <version>
  #|
  #|Examples:
  #|  moonver get alpha 2026.01.1
  #|  moonver up rc 2026.01.1-rc.1
  #|  moonver up release 2026.01.1-rc.1
  #|  moonver scheme YYYY.MM.MICRO 2026.01.1
  #|
  #|Notes:
  #|  - version may be prefixed with "v" (e.g. v2026.01.1)

///|
fn print_usage() -> Unit {
  println(usage_text)
}

///|
fn strip_v(version : String) -> String {
  match version {
    [.. "v", .. rest] => rest.to_string()
    [.. "V", .. rest] => rest.to_string()
    _ => version
  }
}

///|
fn parse_version(value : String) -> @calver.Calver? {
  parse_version_with_scheme(value, @calver.default_scheme)
}

///|
fn parse_version_with_scheme(
  value : String,
  scheme : String,
) -> @calver.Calver? {
  let normalized = strip_v(value)
  match @calver.try_parse_with_scheme(normalized, scheme) {
    Ok(version) => Some(version)
    Err(_) => None
  }
}

///|
fn release_version(version : @calver.Calver) -> @calver.Calver {
  {
    scheme: version.scheme,
    year: version.year,
    month: version.month,
    week: version.week,
    day: version.day,
    micro: version.micro,
    pre: [],
    build: [],
  }
}

///|
fn keep_prerelease(version : @calver.Calver) -> @calver.Calver {
  version.strip_build()
}

///|
fn with_prerelease(
  version : @calver.Calver,
  label : String,
  number : Int,
) -> @calver.Calver {
  {
    scheme: version.scheme,
    year: version.year,
    month: version.month,
    week: version.week,
    day: version.day,
    micro: version.micro,
    pre: [@calver.PreId::Str(label), @calver.PreId::Num(number)],
    build: [],
  }
}

///|
fn get_prerelease(
  version : @calver.Calver,
  label : String,
  base : Int,
) -> @calver.Calver {
  match version.pre {
    [@calver.PreId::Str(name), @calver.PreId::Num(_), ..] if name == label =>
      keep_prerelease(version)
    [@calver.PreId::Str(name), ..] if name == label =>
      with_prerelease(version, label, base)
    _ => with_prerelease(version, label, base)
  }
}

///|
fn up_prerelease(version : @calver.Calver, label : String) -> @calver.Calver {
  match version.pre {
    [@calver.PreId::Str(name), @calver.PreId::Num(num), ..] if name == label =>
      with_prerelease(version, label, num + 1)
    [@calver.PreId::Str(name), ..] if name == label =>
      with_prerelease(version, label, 1)
    _ => with_prerelease(release_version(version), label, 1)
  }
}

///|
fn up_release(version : @calver.Calver) -> @calver.Calver {
  release_version(version)
}

///|
fn get_version(kind : String, version : @calver.Calver) -> @calver.Calver? {
  match kind {
    "alpha" => Some(get_prerelease(version, "alpha", 0))
    "beta" => Some(get_prerelease(version, "beta", 0))
    "rc" => Some(get_prerelease(version, "rc", 0))
    "release" => Some(release_version(version))
    _ => None
  }
}

///|
fn up_version(kind : String, version : @calver.Calver) -> @calver.Calver? {
  match kind {
    "alpha" => Some(up_prerelease(version, "alpha"))
    "beta" => Some(up_prerelease(version, "beta"))
    "rc" => Some(up_prerelease(version, "rc"))
    "release" => Some(up_release(version))
    "pre" => version.inc("pre")
    "prerelease" => version.inc("prerelease")
    _ => None
  }
}

///|
fn to_output(version : @calver.Calver) -> String {
  "v" + version.to_string()
}

///|
fn parse_non_neg_int(value : String) -> Int? {
  let result : Result[Int, Error] = try? @strconv.parse_int(value, base=10)
  match result {
    Ok(num) if num >= 0 => Some(num)
    _ => None
  }
}

///|
fn parse_init_options(
  args : ArrayView[String],
  release : String,
  alpha : Int,
  beta : Int,
  rc : Int,
) -> Result[(String, Int, Int, Int), String] {
  match args {
    [] => Ok((release, alpha, beta, rc))
    ["-r", value, .. rest] => parse_init_options(rest, value, alpha, beta, rc)
    ["--release", value, .. rest] =>
      parse_init_options(rest, value, alpha, beta, rc)
    ["-a", value, .. rest] =>
      match parse_non_neg_int(value) {
        Some(num) => parse_init_options(rest, release, num, beta, rc)
        None => Err("invalid alpha: \{value}")
      }
    ["--alpha", value, .. rest] =>
      match parse_non_neg_int(value) {
        Some(num) => parse_init_options(rest, release, num, beta, rc)
        None => Err("invalid alpha: \{value}")
      }
    ["-b", value, .. rest] =>
      match parse_non_neg_int(value) {
        Some(num) => parse_init_options(rest, release, alpha, num, rc)
        None => Err("invalid beta: \{value}")
      }
    ["--beta", value, .. rest] =>
      match parse_non_neg_int(value) {
        Some(num) => parse_init_options(rest, release, alpha, num, rc)
        None => Err("invalid beta: \{value}")
      }
    ["-c", value, .. rest] =>
      match parse_non_neg_int(value) {
        Some(num) => parse_init_options(rest, release, alpha, beta, num)
        None => Err("invalid rc: \{value}")
      }
    ["--rc", value, .. rest] =>
      match parse_non_neg_int(value) {
        Some(num) => parse_init_options(rest, release, alpha, beta, num)
        None => Err("invalid rc: \{value}")
      }
    ["--force", .. rest] => parse_init_options(rest, release, alpha, beta, rc)
    [unknown, ..] => Err("unknown option: \{unknown}")
  }
}

///|
fn handle_init(args : ArrayView[String]) -> Unit {
  let result = parse_init_options(args, "1.0.0", 0, 0, 0)
  match result {
    Err(msg) => {
      println(msg)
      print_usage()
    }
    Ok((release, alpha, beta, rc)) =>
      match parse_version(release) {
        None => {
          println("invalid release: \{release}")
          print_usage()
        }
        Some(version) => {
          let clean = release_version(version)
          println("release: \{clean.to_string()}")
          println("alpha: \{alpha}")
          println("beta: \{beta}")
          println("rc: \{rc}")
        }
      }
  }
}

///|
fn handle_get(kind : String, version_raw : String) -> Unit {
  match parse_version(version_raw) {
    None => {
      println("invalid version: \{version_raw}")
      print_usage()
    }
    Some(version) =>
      match get_version(kind, version) {
        None => {
          println("unknown get target: \{kind}")
          print_usage()
        }
        Some(next) => println(to_output(next))
      }
  }
}

///|
fn handle_up(kind : String, version_raw : String) -> Unit {
  match parse_version(version_raw) {
    None => {
      println("invalid version: \{version_raw}")
      print_usage()
    }
    Some(version) =>
      match up_version(kind, version) {
        None => {
          println("unknown up target: \{kind}")
          print_usage()
        }
        Some(next) => println(to_output(next))
      }
  }
}

///|
fn handle_scheme(pattern : String, version_raw : String) -> Unit {
  match parse_version_with_scheme(version_raw, pattern) {
    None => {
      println("invalid version: \{version_raw}")
      print_usage()
    }
    Some(version) => println(to_output(version))
  }
}

///|
fn main {
  let args = @env.args()
  match args {
    [_, "-h", ..] => print_usage()
    [_, "--help", ..] => print_usage()
    [_, "help", ..] => print_usage()
    [_, "init", .. rest] => handle_init(rest)
    [_, "get", kind, version, ..] => handle_get(kind, version)
    [_, "up", kind, version, ..] => handle_up(kind, version)
    [_, "scheme", pattern, version, ..] => handle_scheme(pattern, version)
    _ => print_usage()
  }
}
