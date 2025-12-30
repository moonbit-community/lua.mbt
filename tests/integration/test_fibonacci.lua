-- Test: Fibonacci with function and control flow
function fib(n)
  if n <= 1 then
    return n
  else
    local a = fib(n - 1)
    local b = fib(n - 2)
    return a + b
  end
end

local result = fib(6)
