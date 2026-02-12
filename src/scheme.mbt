///|
priv enum SchemeToken {
  Year4
  Year2
  Year0
  Month
  Month0
  Week
  Week0
  Day
  Day0
  Micro
}

///|
priv enum SchemePart {
  Token(SchemeToken)
  Literal(String)
}

///|
priv struct Scheme {
  parts : Array[SchemePart]
  tokens : Array[SchemeToken]
}

///|
fn is_alnum(c : Char) -> Bool {
  c is ('0'..='9') || c is ('a'..='z') || c is ('A'..='Z')
}

///|
fn is_digit(c : Char) -> Bool {
  c is ('0'..='9')
}

///|
fn scheme_token_width(token : SchemeToken) -> Int? {
  match token {
    SchemeToken::Year4 => Some(4)
    SchemeToken::Year2 => None
    SchemeToken::Year0 => None
    SchemeToken::Month => None
    SchemeToken::Month0 => Some(2)
    SchemeToken::Week => None
    SchemeToken::Week0 => Some(2)
    SchemeToken::Day => None
    SchemeToken::Day0 => Some(2)
    SchemeToken::Micro => None
  }
}

///|
fn scheme_token_is_year(token : SchemeToken) -> Bool {
  match token {
    SchemeToken::Year4 | SchemeToken::Year2 | SchemeToken::Year0 => true
    _ => false
  }
}

///|
fn scheme_token_is_variable(token : SchemeToken) -> Bool {
  scheme_token_width(token) is None
}

///|
fn slice_equals(value : String, start : Int, target : String) -> Bool {
  let end = start + target.length()
  if end > value.length() {
    false
  } else {
    let slice = value[start:end] catch { _ => "" }
    slice.to_string() == target
  }
}

///|
fn match_scheme_token(value : String, start : Int) -> (SchemeToken, Int)? {
  if slice_equals(value, start, "MICRO") {
    Some((SchemeToken::Micro, 5))
  } else if slice_equals(value, start, "YYYY") {
    Some((SchemeToken::Year4, 4))
  } else if slice_equals(value, start, "YY") {
    Some((SchemeToken::Year2, 2))
  } else if slice_equals(value, start, "0Y") {
    Some((SchemeToken::Year0, 2))
  } else if slice_equals(value, start, "0M") {
    Some((SchemeToken::Month0, 2))
  } else if slice_equals(value, start, "MM") {
    Some((SchemeToken::Month, 2))
  } else if slice_equals(value, start, "0W") {
    Some((SchemeToken::Week0, 2))
  } else if slice_equals(value, start, "WW") {
    Some((SchemeToken::Week, 2))
  } else if slice_equals(value, start, "0D") {
    Some((SchemeToken::Day0, 2))
  } else if slice_equals(value, start, "DD") {
    Some((SchemeToken::Day, 2))
  } else {
    None
  }
}

///|
fn parse_scheme(pattern : String) -> Scheme raise CalverError {
  let parts : Array[SchemePart] = []
  let tokens : Array[SchemeToken] = []
  let mut literal = StringBuilder::new()
  let mut idx = 0
  let len = pattern.length()
  while idx < len {
    match match_scheme_token(pattern, idx) {
      Some((token, width)) => {
        let text = literal.to_string()
        if text != "" {
          parts.push(SchemePart::Literal(text))
        }
        parts.push(SchemePart::Token(token))
        tokens.push(token)
        literal = StringBuilder::new()
        idx = idx + width
      }
      None =>
        match pattern.get_char(idx) {
          None => raise CalverError::InvalidScheme("unexpected end")
          Some(ch) =>
            if is_alnum(ch) {
              raise CalverError::InvalidScheme("unexpected token: \{pattern}")
            } else {
              literal.write_char(ch)
              idx = idx + 1
            }
        }
    }
  }
  let text = literal.to_string()
  if text != "" {
    parts.push(SchemePart::Literal(text))
  }
  validate_scheme(pattern, parts, tokens)
  { parts, tokens }
}

///|
fn validate_scheme(
  pattern : String,
  parts : Array[SchemePart],
  tokens : Array[SchemeToken],
) -> Unit raise CalverError {
  let mut year_seen = false
  let mut month_seen = false
  let mut week_seen = false
  let mut day_seen = false
  let mut micro_seen = false
  for token in tokens {
    match token {
      SchemeToken::Year4 | SchemeToken::Year2 | SchemeToken::Year0 =>
        if year_seen {
          raise CalverError::InvalidScheme("duplicate year token")
        } else {
          year_seen = true
        }
      SchemeToken::Month | SchemeToken::Month0 =>
        if month_seen {
          raise CalverError::InvalidScheme("duplicate month token")
        } else {
          month_seen = true
        }
      SchemeToken::Week | SchemeToken::Week0 =>
        if week_seen {
          raise CalverError::InvalidScheme("duplicate week token")
        } else {
          week_seen = true
        }
      SchemeToken::Day | SchemeToken::Day0 =>
        if day_seen {
          raise CalverError::InvalidScheme("duplicate day token")
        } else {
          day_seen = true
        }
      SchemeToken::Micro =>
        if micro_seen {
          raise CalverError::InvalidScheme("duplicate micro token")
        } else {
          micro_seen = true
        }
    }
  }
  if !year_seen {
    raise CalverError::InvalidScheme("missing year token")
  }
  if month_seen && week_seen {
    raise CalverError::InvalidScheme("month and week are exclusive")
  }
  if day_seen && !month_seen {
    raise CalverError::InvalidScheme("day requires month")
  }
  let mut token_index = 0
  let mut saw_literal = false
  let mut prev_token : SchemeToken? = None
  for part in parts {
    match part {
      SchemePart::Literal(_) => saw_literal = true
      SchemePart::Token(token) => {
        if token_index == 0 && !scheme_token_is_year(token) {
          raise CalverError::InvalidScheme("year must be first token")
        }
        match prev_token {
          Some(prev) if !saw_literal && scheme_token_is_variable(prev) =>
            raise CalverError::InvalidScheme(
              "separator required after variable token",
            )
          _ => ()
        }
        prev_token = Some(token)
        saw_literal = false
        token_index = token_index + 1
      }
    }
  }
  validate_scheme_order(pattern, tokens)
}

///|
fn validate_scheme_order(
  pattern : String,
  tokens : Array[SchemeToken],
) -> Unit raise CalverError {
  let mut idx = 0
  let mut seen_year = false
  let mut seen_month = false
  let mut seen_week = false
  let mut seen_day = false
  let mut seen_micro = false
  for token in tokens {
    if idx == 0 && !scheme_token_is_year(token) {
      raise CalverError::InvalidScheme("year must be first token")
    }
    if scheme_token_is_year(token) {
      if seen_year {
        raise CalverError::InvalidScheme("duplicate year token")
      }
      seen_year = true
    } else if token is (SchemeToken::Month | SchemeToken::Month0) {
      if seen_week || seen_micro {
        raise CalverError::InvalidScheme("month position invalid")
      }
      seen_month = true
    } else if token is (SchemeToken::Week | SchemeToken::Week0) {
      if seen_month || seen_day || seen_micro {
        raise CalverError::InvalidScheme("week position invalid")
      }
      seen_week = true
    } else if token is (SchemeToken::Day | SchemeToken::Day0) {
      if !seen_month || seen_micro {
        raise CalverError::InvalidScheme("day position invalid")
      }
      seen_day = true
    } else if token is SchemeToken::Micro {
      seen_micro = true
    }
    idx = idx + 1
  }
  if tokens.is_empty() {
    raise CalverError::InvalidScheme("empty scheme: \{pattern}")
  }
}

///|
fn read_fixed_digits(value : String, start : Int, count : Int) -> String? {
  let end = start + count
  if end > value.length() {
    None
  } else {
    let slice = value[start:end] catch { _ => "" }
    let text = slice.to_string()
    if text.length() != count {
      None
    } else {
      Some(text)
    }
  }
}

///|
fn read_variable_digits(value : String, start : Int) -> (String, Int) {
  let len = value.length()
  let mut idx = start
  let sb = StringBuilder::new()
  while idx < len {
    match value.get_char(idx) {
      Some(ch) if is_digit(ch) => {
        sb.write_char(ch)
        idx = idx + 1
      }
      _ => break
    }
  }
  (sb.to_string(), idx)
}

///|
fn ensure_digits(text : String, label~ : String) -> Unit raise CalverError {
  if text is "" {
    raise CalverError::InvalidNumber("\{label}: empty")
  }
  for c in text {
    if !is_digit(c) {
      raise CalverError::InvalidNumber(label)
    }
  }
}

///|
fn reject_leading_zero(
  text : String,
  label~ : String,
) -> Unit raise CalverError {
  if text.length() > 1 && text[0] == '0' {
    raise CalverError::LeadingZero("\{label}: \{text}")
  }
}

///|
fn parse_number(text : String, label~ : String) -> Int raise CalverError {
  @strconv.parse_int(text, base=10) catch {
    _ => raise CalverError::InvalidNumber(label)
  }
}

///|
fn parse_year(token : SchemeToken, text : String) -> Int raise CalverError {
  ensure_digits(text, label="year")
  match token {
    SchemeToken::Year4 => {
      if text.length() != 4 {
        raise CalverError::InvalidFormat("expected YYYY")
      }
      parse_number(text, label="year")
    }
    SchemeToken::Year2 => {
      reject_leading_zero(text, label="year")
      2000 + parse_number(text, label="year")
    }
    SchemeToken::Year0 => {
      if text.length() < 2 {
        raise CalverError::InvalidFormat("expected 0Y")
      }
      2000 + parse_number(text, label="year")
    }
    _ => raise CalverError::InvalidFormat("expected year token")
  }
}

///|
fn parse_range_number(
  token : SchemeToken,
  text : String,
  label~ : String,
  min : Int,
  max : Int,
) -> Int raise CalverError {
  ensure_digits(text, label~)
  if token is (SchemeToken::Week | SchemeToken::Day) {
    reject_leading_zero(text, label~)
  }
  let value = parse_number(text, label~)
  if value < min || value > max {
    raise CalverError::InvalidNumber("\{label}: \{text}")
  }
  value
}

///|
fn parse_micro(text : String) -> Int raise CalverError {
  ensure_digits(text, label="micro")
  reject_leading_zero(text, label="micro")
  parse_number(text, label="micro")
}

///|
fn parse_core_with_scheme(
  input : String,
  scheme : String,
) -> (Int, Int?, Int?, Int?, Int?, Int) raise CalverError {
  let parsed = parse_scheme(scheme)
  let mut year : Int? = None
  let mut month : Int? = None
  let mut week : Int? = None
  let mut day : Int? = None
  let mut micro : Int? = None
  let mut pos = 0
  for part in parsed.parts {
    match part {
      SchemePart::Literal(text) => {
        if !slice_equals(input, pos, text) {
          raise CalverError::InvalidFormat("expected scheme: \{scheme}")
        }
        pos = pos + text.length()
      }
      SchemePart::Token(token) =>
        match scheme_token_width(token) {
          Some(width) =>
            match read_fixed_digits(input, pos, width) {
              None => raise CalverError::InvalidFormat("expected digits")
              Some(text) => {
                let value = parse_token_value(token, text)
                match token {
                  SchemeToken::Year4
                  | SchemeToken::Year2
                  | SchemeToken::Year0 => year = Some(value)
                  SchemeToken::Month | SchemeToken::Month0 =>
                    month = Some(value)
                  SchemeToken::Week | SchemeToken::Week0 => week = Some(value)
                  SchemeToken::Day | SchemeToken::Day0 => day = Some(value)
                  SchemeToken::Micro => micro = Some(value)
                }
                pos = pos + width
              }
            }
          None => {
            let (text, next_pos) = read_variable_digits(input, pos)
            if text is "" {
              raise CalverError::InvalidFormat("expected digits")
            }
            let value = parse_token_value(token, text)
            match token {
              SchemeToken::Year4 | SchemeToken::Year2 | SchemeToken::Year0 =>
                year = Some(value)
              SchemeToken::Month | SchemeToken::Month0 => month = Some(value)
              SchemeToken::Week | SchemeToken::Week0 => week = Some(value)
              SchemeToken::Day | SchemeToken::Day0 => day = Some(value)
              SchemeToken::Micro => micro = Some(value)
            }
            pos = next_pos
          }
        }
    }
  }
  let final_year = match year {
    Some(value) => value
    None => raise CalverError::InvalidFormat("missing year")
  }
  (final_year, month, week, day, micro, pos)
}

///|
fn parse_token_value(
  token : SchemeToken,
  text : String,
) -> Int raise CalverError {
  match token {
    SchemeToken::Year4 | SchemeToken::Year2 | SchemeToken::Year0 =>
      parse_year(token, text)
    SchemeToken::Month | SchemeToken::Month0 =>
      parse_range_number(token, text, label="month", 1, 12)
    SchemeToken::Week | SchemeToken::Week0 =>
      parse_range_number(token, text, label="week", 1, 53)
    SchemeToken::Day | SchemeToken::Day0 =>
      parse_range_number(token, text, label="day", 1, 31)
    SchemeToken::Micro => parse_micro(text)
  }
}

///|
fn format_core_with_scheme(
  scheme : String,
  year : Int,
  month : Int?,
  week : Int?,
  day : Int?,
  micro : Int?,
) -> String raise CalverError {
  let parsed = parse_scheme(scheme)
  let sb = StringBuilder::new()
  for part in parsed.parts {
    match part {
      SchemePart::Literal(text) => sb.write_string(text)
      SchemePart::Token(token) => {
        let text = format_token_value(token, year, month, week, day, micro)
        sb.write_string(text)
      }
    }
  }
  sb.to_string()
}

///|
fn format_token_value(
  token : SchemeToken,
  year : Int,
  month : Int?,
  week : Int?,
  day : Int?,
  micro : Int?,
) -> String raise CalverError {
  match token {
    SchemeToken::Year4 => year.to_string().pad_start(4, '0')
    SchemeToken::Year2 => {
      let short = year - 2000
      short.to_string()
    }
    SchemeToken::Year0 => {
      let short = year - 2000
      let text = short.to_string()
      text.pad_start(2, '0')
    }
    SchemeToken::Month =>
      match month {
        None => raise CalverError::InvalidFormat("missing month")
        Some(value) => value.to_string()
      }
    SchemeToken::Month0 =>
      match month {
        None => raise CalverError::InvalidFormat("missing month")
        Some(value) => value.to_string().pad_start(2, '0')
      }
    SchemeToken::Week =>
      match week {
        None => raise CalverError::InvalidFormat("missing week")
        Some(value) => value.to_string()
      }
    SchemeToken::Week0 =>
      match week {
        None => raise CalverError::InvalidFormat("missing week")
        Some(value) => value.to_string().pad_start(2, '0')
      }
    SchemeToken::Day =>
      match day {
        None => raise CalverError::InvalidFormat("missing day")
        Some(value) => value.to_string()
      }
    SchemeToken::Day0 =>
      match day {
        None => raise CalverError::InvalidFormat("missing day")
        Some(value) => value.to_string().pad_start(2, '0')
      }
    SchemeToken::Micro =>
      match micro {
        None => raise CalverError::InvalidFormat("missing micro")
        Some(value) => value.to_string()
      }
  }
}

///|
fn compare_core_with_scheme(scheme : String, a : Calver, b : Calver) -> Int {
  let parsed : Result[Scheme, CalverError] = try? parse_scheme(scheme)
  match parsed {
    Err(_) => compare_string(a.scheme, b.scheme)
    Ok(value) => compare_core_with_parsed(value, a, b)
  }
}

///|
fn compare_core_with_parsed(parsed : Scheme, a : Calver, b : Calver) -> Int {
  for token in parsed.tokens {
    let (left, right) = match token {
      SchemeToken::Year4 | SchemeToken::Year2 | SchemeToken::Year0 =>
        (a.year, b.year)
      SchemeToken::Month | SchemeToken::Month0 =>
        (value_or_zero(a.month), value_or_zero(b.month))
      SchemeToken::Week | SchemeToken::Week0 =>
        (value_or_zero(a.week), value_or_zero(b.week))
      SchemeToken::Day | SchemeToken::Day0 =>
        (value_or_zero(a.day), value_or_zero(b.day))
      SchemeToken::Micro => (value_or_zero(a.micro), value_or_zero(b.micro))
    }
    let cmp = compare_int(left, right)
    if cmp != 0 {
      return cmp
    }
  }
  0
}

///|
fn value_or_zero(value : Int?) -> Int {
  match value {
    Some(v) => v
    None => 0
  }
}
