-- Test: Recursive functions
-- Tests recursion with different patterns

-- Simple recursion - countdown
function countdown(n)
  if n == 0 then
    return 0
  else
    return countdown(n - 1)
  end
end

local r1 = countdown(5)
-- r1 should be 0

-- Factorial
function factorial(n)
  if n <= 1 then
    return 1
  else
    return n * factorial(n - 1)
  end
end

local f5 = factorial(5)
-- f5 should be 120

-- Fibonacci
function fib(n)
  if n <= 1 then
    return n
  else
    local a = fib(n - 1)
    local b = fib(n - 2)
    return a + b
  end
end

local f6 = fib(6)
-- f6 should be 8

-- Sum from 1 to n (recursive)
function sum_to(n)
  if n == 0 then
    return 0
  else
    return n + sum_to(n - 1)
  end
end

local s10 = sum_to(10)
-- s10 should be 55

-- Recursion with multiple base cases
function test(n)
  if n == 0 then
    return 1
  end
  if n == 1 then
    return 2
  end
  return test(n - 1) + test(n - 2)
end

local t5 = test(5)

-- Mutual recursion simulation (one function calling itself)
function even_odd(n)
  if n == 0 then
    return 1  -- 0 is even
  end
  if n == 1 then
    return 0  -- 1 is odd
  end
  return even_odd(n - 2)
end

local is_even_4 = even_odd(4)
local is_even_5 = even_odd(5)
