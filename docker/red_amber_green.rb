
lambda { |stdout,stderr,status|
  output = stdout + stderr
  js_hint_pattern = /^(\d+) error(s?)/
  if js_hint_pattern.match(output)
    :amber
  elsif /^FAIL/.match(output)
    :red
  elsif /^PASS/.match(output)
    :green
  else
    :amber
  end
}
