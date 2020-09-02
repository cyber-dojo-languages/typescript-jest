
lambda { |stdout,stderr,status|
  if status === 0
    return :green
  end
  output = stdout + stderr
  #js_hint_pattern = /^(\d+) error(s?)/
  #if js_hint_pattern.match(output)
  #  return :amber
  #end
  if output.include?('Test suite failed to run')
    :amber
  elsif /^FAIL/.match(output)
    :red
  elsif /^PASS/.match(output)
    :green
  else
    :amber
  end
}
