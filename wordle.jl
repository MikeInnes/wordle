using StatsBase
using MacroTools: @>
import Base: ==

# Templates and matching

const N = 5

const answers = @> joinpath(@__DIR__, "wordle-answers.txt") read String split("\n", keepempty=false)
const guesses = @> joinpath(@__DIR__, "wordle-guesses.txt") read String split("\n", keepempty=false)

const words = vcat(guesses, answers)

struct Template
  include::Set{Char}
  exclude::Vector{Set{Char}}
  known::Vector{Union{Char,Nothing}}
end

Template() = Template(Set{Char}(), [Set{Char}() for i = 1:N], [nothing for i = 1:N])

Base.copy(t::Template) = Template(copy(t.include), copy.(t.exclude), copy(t.known))

a::Template == b::Template =
  a.include == b.include &&
  a.exclude == b.exclude &&
  a.known == b.known

Base.hash(t::Template, h::UInt64) = Base.hash((t.include, t.exclude, t.known), h)

function update!(t::Template, guess, answer)
  for (i, l) in enumerate(guess)
    if l == answer[i]
      push!(t.include, l)
      t.known[i] = l
    elseif l in answer
      push!(t.include, l)
      push!(t.exclude[i], l)
    else
      foreach(ls -> push!(ls, l), t.exclude)
    end
  end
  return t
end

update(t::Template, guess, answer) = update!(copy(t), guess, answer)

splitguess(s::String) = map(x -> x.match, eachmatch(r"\w[_*]?", s))

function template(guesses::Vector{String})
  t = Template()
  for guess in guesses, (i, l) in enumerate(splitguess(guess))
    letter = l[1]
    type = get(l, 2, '!')
    if type == '*'
      push!(t.include, letter)
      t.known[i] = letter
    elseif type == '_'
      push!(t.include, letter)
      push!(t.exclude[i], letter)
    else
      foreach(ls -> push!(ls, letter), t.exclude)
    end
  end
  return t
end

matches(t::Template, w::AbstractString) =
  length(w) == length(t.known) && all(l -> l in w, t.include) &&
  !any(l in ls for (ls, l) in zip(t.exclude, w)) &&
  all(a == nothing || a == b for (a, b) in zip(t.known, w))

matches(t::Template, words = answers) = filter(w -> matches(t, w), words)

matches(guesses, words = answers) = matches(template(guesses), words)

# Entropy-based solving

function expected_remaining(t::Template, guess; words = matches(t, answers))
  r = 0.
  cache = Dict{Template,Float64}()
  for answer in words
    t′ = update(t, guess, answer)
    r += get!(cache, t′) do
      log(length(matches(t′, words)))
    end
  end
  return exp(r / length(words))
end

expected_remaining(guess) = expected_remaining(Template(), guess)

function nextguess(t::Template, words = matches(t, answers))
  cache = Dict{Template,Float64}()
  _, i = findmin(w -> expected_remaining(t, w, words = words), words)
  return words[i]
end

nextguess(guesses) = nextguess(template(guesses))

function nextguess2(t::Template, ws = matches(t, answers))
  rest = setdiff(words, ws)
  s1, i1 = findmin(w -> expected_remaining(t, w, words = ws), ws)
  s2, i2 = findmin(w -> expected_remaining(t, w, words = ws), rest)
  return s2 < s1 ? rest[i2] : ws[i1]
end

nextguess2(guesses) = nextguess2(template(guesses))

function solve(start, answer; words = answers)
  answer == start && return 1
  t = update!(Template(), start, answer)
  words = matches(t, answers)
  i = 1
  while length(words) > 1
    guess = nextguess2(t, words)
    update!(t, guess, answer)
    words = matches(t, words)
    i += 1
  end
  return i+1
end
