guard :minitest do
  watch(%r{^test/test_helper\.rb$}) { 'test' }
  watch(%r{^test/(.*)\/?test_(.*)\.rb$})
  watch(%r{^app/(.+)\.rb$}) { |m| "test/#{m[1]}_test.rb" }
end
