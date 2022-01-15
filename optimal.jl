include("wordle.jl")

# A simple minimax-like Wordle solver.
#
# The score for a set of words is the average number of guesses needed to solve
# it.
#     – which is the minimum score of each possible guess.
# The score for a guess (relative to a word set) is the average score of the
# words remaining after making that guess (plus one).
#
# This is a simple recursive algorithm, but also an exponential one, so it
# doesn't work if there are more than a few hundred guesses.

function score(t::Template, words, guess; cache = Dict{Template,Float64}())
  s = 0.
  for word in words
    s += 1
    if word != guess
      t′ = update(t, guess, word)
      s += score(t′, matches(t′, words); cache)
    end
  end
  return s/length(words)
end

function score(t::Template, words; cache = Dict{Template,Float64}())
  get!(cache, t) do
    s, i = findmin(score(t, words, guess; cache) for guess in words)
    return s
  end
end

score(words) = score(Template(), words)

function nextguess_optimal(t::Template, words)
  s, i = findmin(score(t, words, guess) for guess in words)
  return words[i]
end

# nextguess_optimal(Template(), answers[1:10])
