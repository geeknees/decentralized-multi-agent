# ABOUTME: Reads Claude's raw response from stdin, extracts the first JSON object
# ABOUTME: Prints normalized JSON to stdout; prints {"actions":[]} on failure

require 'json'

text = $stdin.read
match = text.match(/\{.*\}/m)
if match
  begin
    puts JSON.dump(JSON.parse(match[0]))
  rescue JSON::ParserError
    puts '{"actions":[]}'
  end
else
  puts '{"actions":[]}'
end
