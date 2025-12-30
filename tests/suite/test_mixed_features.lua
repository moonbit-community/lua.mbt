-- Test: Mixed features
-- Tests combining multiple language features together

-- Fibonacci with memoization using table
function fib_memo(n)
  local memo = {}
  memo[0] = 0
  memo[1] = 1

  for i = 2, n do
    memo[i] = memo[i-1] + memo[i-2]
  end

  return memo[n]
end

local f10 = fib_memo(10)
-- f10 should be 55

-- Prime checking function
function is_prime(n)
  if n <= 1 then
    return 0
  end
  if n == 2 then
    return 1
  end

  local i = 2
  while i * i <= n do
    if n - (n / i) * i == 0 then  -- Simple modulo check
      return 0
    end
    i = i + 1
  end

  return 1
end

local p7 = is_prime(7)   -- Should be 1 (true)
local p10 = is_prime(10) -- Should be 0 (false)

-- Array reversal
function reverse(t, n)
  local result = {}
  for i = 1, n do
    result[i] = t[n - i + 1]
  end
  return result
end

local arr = {1, 2, 3, 4, 5}
local rev = reverse(arr, 5)
-- rev should be {5, 4, 3, 2, 1}

-- Binary search (simplified for integers)
function binary_search(t, target, low, high)
  if low > high then
    return 0
  end

  local mid = (low + high) / 2
  -- Convert to integer by truncation
  if mid > (low + high) / 2 - 0.5 then
    mid = mid - 1
  end
  mid = mid + 1  -- Adjust to 1-based indexing

  local mid_val = t[mid]

  if mid_val == target then
    return mid
  end

  if mid_val < target then
    return binary_search(t, target, mid + 1, high)
  else
    return binary_search(t, target, low, mid - 1)
  end
end

local sorted = {1, 3, 5, 7, 9, 11, 13, 15}
local idx = binary_search(sorted, 7, 1, 8)
-- idx should be 4

-- Nested data structures
local data = {{1, 2}, {3, 4}, {5, 6}}
function sum_nested(t)
  local total = 0
  for i = 1, 3 do
    for j = 1, 2 do
      total = total + t[i][j]
    end
  end
  return total
end

local s = sum_nested(data)
-- s should be 21
