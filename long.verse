
Long<public>:= module {
    using { /Verse.org/Simulation }

    BASE<internal>:int = 1000000000
    BASE_DIGITS<internal>:int = 9

    long<public>:= struct<persistable><computes><concrete>{
        @editable
        Value:string = array{}
        Limbs:[]int = array{}
        IsNegative:logic = false
    }

    # --- Internal Helper Functions ---

    Parse<internal>(Input:long)<computes>:long = {
        if (Input.Value.Length = 0) then {
            return Input
        }

        NumbString := Input.Value[0] = '-' and Input.Value.Slice[1] or Input.Value
        IsNegative := Input.Value[0] = '-' and true or false
        Limbs := for {
            Index := 0..NumbString.Length
            EndIndex := NumbString.Length - Index
            StartIndex := Max(0, EndIndex - BASE_DIGITS)
            LimbString := NumbString.Slice[StartIndex, EndIndex - 1]
        }do LimbToInt(LimbString, 0, 0)

        return long {
            Limbs := Limbs
            IsNegative := IsNegative
        }
    }

    LimbToInt<internal>(Input:string, Index:int, Num:int)<computes>:int = {
        return LimbToInt(Input, Index + 1, Num * 10 + case(Input[Index]) {
            '0' => 0; '1' => 1; '2' => 2
            '3' => 3; '4' => 4; '5' => 5
            '6' => 6; '7' => 7; '8' => 8
            '9' => 9

            _ => Err("ERROR: long value are unvalid")
        }) or Num
    }

    GreatHandler<internal>(Left:long, Right:long)<computes>:logic = {
        for(Index := 1..Left.Limbs.Length, CurrentIndex := Left.Limbs.Length - Index) do {
            if (Left.Limbs[CurrentIndex] > Right.Limbs[CurrentIndex]) then return true
            if (Left.Limbs[CurrentIndex] < Right.Limbs[CurrentIndex]) then return false
        }
        return false
    }

    TrimZeros<internal>(Input:[]int)<computes>:[]int = {
        if (Input.Length <= 1) then {
            return Input
        }

        LastChunk := Input[Input.Length-1] or Err()
        return LastChunk = 0 and TrimZeros(Input.Slice[0, Input.Length - 2]) or Input
    }

    UnsignedAdd<internal>(Left:[]int, Right:[]int, ?Carry:int = 0)<computes>:[]int = {
        if (Left.Length = 0 and Right.Length = 0) then {
            return Carry > 0 and array{Carry} or array{}
        }

        LChunk := Left[0] or 0
        RChunk := Right[0] or 0

        LTail := Left.Slice[1] or array{}
        RTail := Right.Slice[1] or array{}

        Total := LChunk + RChunk + Carry
        Digit := Mod[Total, BASE] or Err()
        Extra := Floor(Total / BASE) or Err()

        RemainingLimbs := UnsignedAdd(LTail, RTail, ?Carry := Extra)

        return array{Digit} + RemainingLimbs
    }

    UnsignedSub<internal>(Left:[]int, Right:[]int)<computes>:[]int = {
        RawResult := UnsignedSubHandler(Left, Right)
        return TrimZeros(RawResult)
    }

    UnsignedSubHandler<internal>(Left:[]int, Right:[]int, ?Borrow:int = 0)<computes>:[]int = {
        if (Left.Length = 0 and Right.Length = 0) then {
            return array{}
        }

        LLimb := Left[0] or 0
        RLimb := Right[0] or 0

        LTail := Left.Slice[1] or array{}
        RTail := Right.Slice[1] or array{}

        Diff := LLimb - RLimb - Borrow
        Digit := Diff < 0 and Diff + BASE or Diff
        Extra := Diff < 0 and 1 or 0

        RemainingLimbs := UnsignedSubHandler(LTail, RTail, ?Borrow := Extra)

        return array{Digit} + RemainingLimbs
    }

    UnsignedMul<internal>(Left:[]int, Right:[]int)<computes>:[]int = {
        if (Left.Length = 0 or Left.Length = 1 and Left[0] = 0) then {
            return array{0}
        }

        if (Right.Length = 1 and Right[0] = 0) then {
            return array{0}
        }

        CurrentLimb := Left[0] or 0
        RemainingLimbs := Left.Slice[1] or array{}

        Term1 := UnsignedMulHandler(Right, CurrentLimb)

        Term2Recursive := UnsignedMul(RemainingLimbs, Right)

        Term2Shifted := Term2Recursive.Length = 1 and Term2Recursive[0] = 0 and Term2Recursive or array{0} + Term2Recursive

        Result := UnsignedAdd(Term1, Term2Shifted)

        return Result
    }

    UnsignedMulHandler<internal>(Limbs:[]int, Multiplier:int, ?Carry:int = 0)<computes>:[]int = {
        if (Limbs.Length = 0) then {
            return Carry > 0 and array{Carry} or array{}
        }

        CurrentLimb := Limbs[0] or 0
        RemainingLimbs := Limbs.Slice[1] or array{}
        Product := CurrentLimb * Multiplier + Carry

        NewLimb := Mod[Product, BASE] or Err()
        NewCarry := Floor(Product / BASE) or Err()

        ResultTail := UnsignedMulHandler(RemainingLimbs, Multiplier, ?Carry := NewCarry)

        return array{NewLimb} + ResultTail
    }

    UnsignedGreatOrEqual<internal>(Left:[]int, Right:[]int)<computes>:logic = {
        if (Left.Length > Right.Length) then { return true }
        if (Left.Length < Right.Length) then { return false }

        for(Index := 1..Left.Length, CurrentIndex := Left.Length - Index) do {
            if (Left[CurrentIndex] > Right[CurrentIndex]) then { return true }
            if (Left[CurrentIndex] < Right[CurrentIndex]) then { return false }
        }

        return true
    }

    FindQuotientLimb<internal>(Current:[]int, Divisor:[]int, ?Low:int = 0, ?High:int = BASE - 1, ?BestQ:int = 0)<computes>:int = {
        if (Low > High) then {
            return BestQ
        }

        Mid := Floor((Low + High) / 2) or 0

        Product := UnsignedMulHandler(Divisor, Mid)

        return UnsignedGreatOrEqual(Current, Product)? and FindQuotientLimb(Current, Divisor, ?Low := Mid + 1, ?High := High, ?BestQ := Mid) or (
            FindQuotientLimb(Current, Divisor, ?Low := Low, ?High := Mid - 1, ?BestQ := BestQ)
        )
    }

    ReverseLimbs<internal>(Limbs:[]int)<computes>:[]int = {
        return for (Index := 1..Limbs.Length, ReverseIndex := Limbs.Length - Index, Limb := Limbs[ReverseIndex]) do {
            Limb
        }
    }

    UnsignedDivModHandler<internal>(
        Dividend:[]int,     # The full (little-endian) dividend
        Divisor:[]int,      # The divisor
        Index:int,          # Current limb index (starts at Dividend.Length - 1)
        CurrentRemainder:[]int, # Remainder from the previous step
        QuotientLimbs:[]int # Partially built (big-endian) quotient
    )<computes>:tuple([]int, []int) = {

        CurrentLimb := Dividend[Index] or 0

        # 1. "Bring down" the next limb:
        # CurrentDividend = (CurrentRemainder * BASE) + CurrentLimb
        # In little-endian: {CurrentLimb} + {R0, R1, ...} -> {CurrentLimb, R0, R1, ...}

        # (CurrentRemainder * BASE) -> {0, R0, R1, ...}
        ShiftedRemainder := CurrentRemainder.Length = 1 and CurrentRemainder[0] = 0 and array{0} or array{0} + CurrentRemainder

        # (R * BASE) + CurrentLimb
        TailOfRemainder := ShiftedRemainder.Slice[1] or array{}
        CurrentDividend := array{CurrentLimb} + TailOfRemainder
        TrimmedDividend := TrimZeros(CurrentDividend)
        
        # 2. Find quotient for this step
        QuotientLimb := FindQuotientLimb(TrimmedDividend, Divisor)
        
        # 3. Add to quotient (handling leading zeros)
        NewQuotientLimbs := (QuotientLimbs.Length > 0 or QuotientLimb > 0) and QuotientLimbs + array{QuotientLimb} or QuotientLimbs

        # 4. Find new remainder
        Product := UnsignedMulHandler(Divisor, QuotientLimb)
        NewRemainder := UnsignedSub(TrimmedDividend, Product)

        # 5. Base case or recurse
            # Last limb processed, return final results or
            # Recurse with the next limb (Index - 1)
        return Index = 0 and (NewQuotientLimbs, NewRemainder) or (
            UnsignedDivModHandler(Dividend, Divisor, Index - 1, NewRemainder, NewQuotientLimbs)
        )
    }

    # Wrapper for the unsigned division, sets up and reverses the result
    UnsignedDivMod<internal>(Dividend:[]int, Divisor:[]int)<computes>:tuple([]int, []int) = {
        # Start the recursive process from the most significant limb (Index = Length - 1)
        # Pass array{0} as the initial remainder and array{} as the initial quotient
        Result := UnsignedDivModHandler(Dividend, Divisor, Dividend.Length - 1, array{0}, array{})

        BigEndianQuotient := Result(0)
        FinalRemainder := Result(1)
        
        # The quotient was built big-endian, so we must reverse it
        ReversedQuotient := ReverseLimbs(BigEndianQuotient)
        
        # Handle edge case where quotient is 0
        FinalQuotient := ReversedQuotient.Length = 0 and array{0} or TrimZeros(ReversedQuotient)

        return (FinalQuotient, TrimZeros(FinalRemainder))
    }

    # --- Public Helper Functions ---

    ToString<public>(Input:long)<computes>:string = {
        Parsed := Parse(Input)
        Length := Parsed.Limbs.Length
        String := Concatenate(for(Index := 1..Length, Digit := Parsed.Limbs[Length - Index]) do "{Digit}")
        return Parsed.IsNegative? and "-" + String or String
    }

    FromInt<public>(Value:int)<computes>:long = {
        return Parse(long{Value := "{ToString(Value)}"})
    }

    Equal<public>(Left:long, Right:long)<computes><decides>:void = {
        Left.IsNegative = Right.IsNegative
        Left.Limbs.Length = Right.Limbs.Length
        for(Index := 0..Left.Limbs.Length - 1) do Left.Limbs[Index] = Right.Limbs[Index]
    }

    Great<public>(Left:long, Right:long)<computes><decides>:void = {
        not Left.IsNegative? and Right.IsNegative? or
        not Left.IsNegative? and Left.Limbs.Length > Right.Limbs.Length or GreatHandler(Left, Right)?
        Left.IsNegative? and Left.Limbs.Length < Right.Limbs.Length or GreatHandler(Right, Left)?
    }

    Small<public>(Left:long, Right:long)<computes><decides>:void = {
        Great[Right, Left]
    }

    # --- Public Arithmetics Operators ---

    operator'+'<public>(Left:long, Right:long)<computes>:long = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)

        if (LParsed.IsNegative = RParsed.IsNegative) then {
            return long {
                Limbs := UnsignedAdd(LParsed.Limbs, RParsed.Limbs)
                IsNegative := LParsed.IsNegative
            }
        }

        AbsLeft := long {Limbs := LParsed.Limbs, IsNegative := false}
        AbsRight := long {Limbs := RParsed.Limbs, IsNegative := false}

        Result := Great[AbsLeft, AbsRight] and (UnsignedSub(LParsed.Limbs, RParsed.Limbs), LParsed.IsNegative) or
                  Small[AbsLeft, AbsRight] and (UnsignedSub(RParsed.Limbs, LParsed.Limbs), RParsed.IsNegative) or
                  (array{0}, false)

        return long {
            Limbs := Result(0)
            IsNegative := Result(1)
        }
    }

    operator'-'<public>(Left:long, Right:long)<computes>:long = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)
        FlippedRight := long { Limbs := RParsed.Limbs, IsNegative := not RParsed.IsNegative? and true or false}
        return LParsed + FlippedRight
    }

    operator'*'<public>(Left:long, Right:long)<computes>:long = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)
        Limbs := UnsignedMul(LParsed.Limbs, RParsed.Limbs)
        IsNegative := LParsed.IsNegative <> RParsed.IsNegative and true or false
        return long {Limbs := Limbs, IsNegative := IsNegative}
    }

    operator'/'<public>(Left:long, Right:long)<computes>:long = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)

        # 1. Check for division by zero
        if (RParsed.Limbs.Length = 1 and RParsed.Limbs[0] = 0) {
            Err("ERROR: Division by zero")
            return long{} # Or use panic()
        }

        # 2. Check if dividend is zero
        if (LParsed.Limbs.Length = 1 and LParsed.Limbs[0] = 0) {
            return long{Limbs := array{0}, IsNegative := false}
        }

        # 3. Compare absolute values
        AbsLeft := LParsed.Limbs
        AbsRight := RParsed.Limbs
        
        if (not UnsignedGreatOrEqual(AbsLeft, AbsRight)?) {
            # |Left| < |Right|, so quotient is 0
            return long{Limbs := array{0}, IsNegative := false}
        }

        # 4. Perform unsigned division
        Result := UnsignedDivMod(AbsLeft, AbsRight)
        ResultQuotient := Result(0)
        ResultRemainder := Result(1)

        # 5. Determine sign
        IsNegative := LParsed.IsNegative <> RParsed.IsNegative and true or false

        return long {
            Limbs := ResultQuotient
            IsNegative := IsNegative
        }
    }

    Mod<public>(Left:long, Right:long)<computes>:long = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)

        # 1. Check for modulo by zero
        if (RParsed.Limbs.Length = 1 and RParsed.Limbs[0] = 0) {
            Err("ERROR: Modulo by zero")
            return long{} # Or use panic()
        }

        # 2. Check if dividend is zero
        if (LParsed.Limbs.Length = 1 and LParsed.Limbs[0] = 0) {
            return long{Limbs := array{0}, IsNegative := false}
        }

        # 3. Compare absolute values
        AbsLeft := LParsed.Limbs
        AbsRight := RParsed.Limbs

        if (not UnsignedGreatOrEqual(AbsLeft, AbsRight)?) {
            # |Left| < |Right|, remainder is just Left
            return LParsed
        }

        # 4. Perform unsigned division
        Result := UnsignedDivMod(AbsLeft, AbsRight)
        ResultQuotient := Result(0)
        ResultRemainder := Result(1)

        # 5. Sign of remainder always matches the dividend (Left)
        return long {
            Limbs := ResultRemainder
            IsNegative := LParsed.IsNegative
        }
    }

    Mod<public>(Left:long, Right:int)<computes>:long = {
        return Mod(Left, FromInt(Right))
    }

    operator'+'<public>(Left:long, Right:int)<computes>:long = Left + FromInt(Right)
    operator'-'<public>(Left:long, Right:int)<computes>:long = Left - FromInt(Right)
    operator'*'<public>(Left:long, Right:int)<computes>:long = Left * FromInt(Right)
    operator'/'<public>(Left:long, Right:int)<computes>:long = Left / FromInt(Right)

    operator'+'<public>(Left:int, Right:long)<computes>:long = FromInt(Left) + Right
    operator'-'<public>(Left:int, Right:long)<computes>:long = FromInt(Left) - Right
    operator'*'<public>(Left:int, Right:long)<computes>:long = FromInt(Left) * Right
    operator'/'<public>(Left:int, Right:long)<computes>:long = FromInt(Left) / Right

    # long_test_component := class<final_super>(component) {

    #     OnBeginSimulation<override>():void = {
    #         (super:)OnBeginSimulation()

    #         FirstNumber:long = long {
    #             Value := "2222222222222222222222"
    #         }

    #         SecondNumber:long = long {
    #             Value := "1111222233334444555566"
    #         }


    #         profile("FirstNumber + SecondNumber Time:") {
    #             Print("FirstNumber + SecondNumber = " + ToString(FirstNumber + SecondNumber))
    #         }

    #         profile("FirstNumber - SecondNumber Time:") {
    #             Print("FirstNumber - SecondNumber = " + ToString(FirstNumber - SecondNumber))
    #         }

    #         profile("FirstNumber * SecondNumber Time:") {
    #             Print("FirstNumber * SecondNumber = " + ToString(FirstNumber * SecondNumber))
    #         }

    #         profile("FirstNumber / SecondNumber Time:") {
    #             Print("FirstNumber / SecondNumber = " + ToString(FirstNumber / SecondNumber))
    #         }

    #         profile("SecondNumber + FirstNumber Time:") {
    #             Print("SecondNumber + FirstNumber = " + ToString(SecondNumber + FirstNumber))
    #         }

    #         profile("SecondNumber - FirstNumber Time:") {
    #             Print("SecondNumber - FirstNumber = " + ToString(SecondNumber - FirstNumber))
    #         }

    #         profile("SecondNumber * FirstNumber Time:") {
    #             Print("SecondNumber * FirstNumber = " + ToString(SecondNumber * FirstNumber))
    #         }

    #         profile("SecondNumber / FirstNumber Time:") {
    #             Print("SecondNumber / FirstNumber = " + ToString(SecondNumber / FirstNumber))
    #         }
    #     }
    # }
}
