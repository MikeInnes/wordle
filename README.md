# Wordle

A simple Wordle solver. Some useful entry points in `wordle.jl`:

```julia
julia> matches(["a_lon_e", "sta_i*n_"])
4-element Vector{SubString{String}}:
 "panic"
 "mania"
 "nadir"
 "manic"
```

Return all possible answers that match the given clues. `a_` is used to indicate that `a` appears in the word, and `a*` is used if `a` is in the right place. All other letters are excluded.

```julia
julia> expected_remaining("strap")
67.50525711860273
```

Get the (geometric) average number of words left after making this guess.

```julia
julia> nextguess(["a_lon_e"])
"drain"

julia> nextguess2(["a_lon_e"])
"cadis"
```

Find the best next guess based on the clues given. `nextguess` will only consider possible answers, while `nextguess2` can try any valid word.

```julia
julia> solve("raise", "bloom")
4
```

Simulate solving a Wordle puzzle where the answer is "bloom", starting with the guess "raise". Returns the number of guesses needed to find the answer.
