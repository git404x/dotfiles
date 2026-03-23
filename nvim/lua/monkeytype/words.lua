local M = {}

local word_list = {
  "the",
  "be",
  "to",
  "of",
  "and",
  "a",
  "in",
  "that",
  "have",
  "i",
  "it",
  "for",
  "not",
  "on",
  "with",
  "he",
  "as",
  "you",
  "do",
  "at",
  "this",
  "but",
  "his",
  "by",
  "from",
  "they",
  "we",
  "say",
  "her",
  "she",
  "or",
  "an",
  "will",
  "my",
  "one",
  "all",
  "would",
  "there",
  "their",
  "what",
}

function M.generate_test(count)
  local test_words = {}
  math.randomseed(os.time())
  for _ = 1, (count or 20) do
    local random_index = math.random(1, #word_list)
    table.insert(test_words, word_list[random_index])
  end
  return table.concat(test_words, " ")
end

return M
