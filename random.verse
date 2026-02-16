
Random<public>:= module {
    using { /Verse.org/Random }
    using { /Verse.org/Simulation }

    weightable<public>:= interface {
        @editable
        Weight<private>:float = 0.0
        GetWeight<public>()<transacts>:float = Weight
    }

    GetRandomElementByWeight<public>(Elements:[]t where t:subtype(weightable))<transacts>:t = {
        var TotalWeight:float = 0.0

        for (Element : Elements) do {
            set TotalWeight += Element.GetWeight()
        }

        var RandomFloat:float = GetRandomFloat(1.0, TotalWeight)

        for (Element : Elements) do {
            set RandomFloat -= Element.GetWeight()

            if (RandomFloat <= 0.0) then {
                return Element
            }
        }

        return Err()
    }

    GetRandomIntBySeed<public>(Low:int, High:int, Seed:int)<transacts>:int = {
        # These constants are from the glibc C standard library.
        M := 2147483648 # Modulus (2^31)
        A := 1103515245 # Multiplier
        C := 12345      # Increment
        N := Mod[A * Seed + C, M] or Err() # Pseudorandom

        Range := High - Low
        Value := Mod[N, Range] or 0

        return Low + Value
    }

    # A BiasStrength < 1.0 will make lower numbers more likely.
    # A BiasStrength > 1.0 will make higher numbers more likely.
    # A BiasStrength between 0.0 and 1.0 results in a uniform (unbiased) distribution.
    GetRandomIntByBias<public>(Low:int, High:int, BiasStrength:float)<transacts>:int = {
        Bias := BiasStrength > 0.0 and BiasStrength or 1.0

        return Bias = 1.0 and GetRandomInt(Low, High) or (
            RandomFloat := GetRandomFloat(0.0, 1.0)
            RandomFloatBiased := Pow(RandomFloat, 1.0 / Bias)

            Range := High - Low
            Value := Floor[RandomFloatBiased * Range] or 0

            Low + Value
        )
    }
}
