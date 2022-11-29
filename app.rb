load "./lib.rb"

s = "Debugging"
f = Foo.new
result = f.bar(s)
binding.debug
puts(result)
