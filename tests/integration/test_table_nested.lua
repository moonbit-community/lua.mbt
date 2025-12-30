-- Test: Nested table structures
local person = {
  name = "Alice",
  age = 25,
  scores = {90, 85, 95}
}

local name = person.name
local age = person.age
local score1 = person.scores[1]
local score2 = person.scores[2]
local score3 = person.scores[3]

-- Calculate average
local avg = (score1 + score2 + score3) / 3
