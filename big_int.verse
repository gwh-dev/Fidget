#ToDo: add linked list maybe instead of array?
BigInt<public>:= module {
    using { /Verse.org/Simulation }

    BASE<internal>:int = 1000000000
    BASE_DIGITS<internal>:int = 9

    big_int<public>:= struct<persistable><computes><concrete>{
        @editable
        Value:string = array{}
        Limbs:[]int = array{}
        IsNegative:logic = false
    }

    # --- Internal Helper Functions ---

    LimbToInt<internal>(Input:string, Index:int, Num:int)<computes>:int = {
        return LimbToInt(Input, Index + 1, Num * 10 + case(Input[Index]) {
            '0' => 0; '1' => 1; '2' => 2
            '3' => 3; '4' => 4; '5' => 5
            '6' => 6; '7' => 7; '8' => 8
            '9' => 9

            _ => Err("ERROR: big_int value are unvalid")
        }) or Num
    }

    StringToLimbs<internal>(NumbString:string)<computes>:[]int = {
        return if {
            NumbString.Length > 0

            StartIndex := Max(0, NumbString.Length - BASE_DIGITS)
            EndIndex := NumbString.Length
            
            LimbString := NumbString.Slice[StartIndex, EndIndex]
            CurrentLimb := LimbToInt(LimbString, 0, 0)
            
            RemainingString := NumbString.Slice[0, StartIndex]
        } then {
            array{CurrentLimb} + StringToLimbs(RemainingString)
        } else {
            array{}
        }
    }

    Parse<internal>(Input:big_int)<computes>:big_int = {
        if (Input.Value.Length = 0) then {
            return Input
        }

        NumbString := Input.Value[0] = '-' and Input.Value.Slice[1] or Input.Value
        IsNegative := Input.Value[0] = '-' and true or false
        Limbs := StringToLimbs(NumbString)

        return big_int {
            Limbs := Limbs
            IsNegative := IsNegative
        }
    }

    GreatHandler<internal>(Left:big_int, Right:big_int)<computes>:logic = {
        for (Index := 1..Left.Limbs.Length, CurrentIndex := Left.Limbs.Length - Index) do {
            if (Left.Limbs[CurrentIndex] > Right.Limbs[CurrentIndex]) then return true
            if (Left.Limbs[CurrentIndex] < Right.Limbs[CurrentIndex]) then return false
        }
        return false
    }

    TrimZeros<internal>(Input:[]int)<computes>:[]int = {
        if (Input.Length <= 1) then {
            return Input
        }

        LastChunk := Input[Input.Length-1] or Err("2123")
        return LastChunk = 0 and TrimZeros(Input.Slice[0, Input.Length - 2]) or Input
    }

    PadLimb<internal>(Input:string)<computes>:string = {
        PaddingNeeded := BASE_DIGITS - Input.Length

        if (PaddingNeeded <= 0) {
            return Input
        }
        
        Padding := for(__ := 1..PaddingNeeded) do '0'
        return Padding + Input
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
        Digit := Mod[Total, BASE] or Err("9312")
        Extra := Floor(Total / BASE) or Err("31223")

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

        NewLimb := Mod[Product, BASE] or Err("3123")
        NewCarry := Floor(Product / BASE) or Err("31543")

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

    # FindQuotientLimb<internal>(Current:[]int, Divisor:[]int, ?Low:int = 0, ?High:int = BASE - 1, ?BestQ:int = 0)<computes>:int = {
    #     Print("Quotient")
    #     if (Low > High) then {
    #         return BestQ
    #     }

    #     Mid := Floor((Low + High) / 2) or 0

    #     Product := UnsignedMulHandler(Divisor, Mid)

    #     return UnsignedGreatOrEqual(Current, Product)? and FindQuotientLimb(Current, Divisor, ?Low := Mid + 1, ?High := High, ?BestQ := Mid) or (
    #         FindQuotientLimb(Current, Divisor, ?Low := Low, ?High := Mid - 1, ?BestQ := BestQ)
    #     )
    # }

    FindQuotientLimb<internal>(Current:[]int, Divisor:[]int)<computes>:int = {
        
        DivisorLen := Divisor.Length
        CurrentLen := Current.Length

        D1 := Divisor[DivisorLen - 1] or 1 # or 1 to prevent /0

        if (CurrentLen < DivisorLen) {
            return 0
        }

        if (CurrentLen = DivisorLen) {
            C0 := Current[CurrentLen - 1] or 0
            if (C0 < D1) { return 0 }
            
            Guess := Quotient[C0, D1] or 0
            
            return AdjustGuess(Current, Divisor, Guess, UnsignedMulHandler(Divisor, Guess))
        }

        if (CurrentLen = DivisorLen + 1) {
            C1 := Current[CurrentLen - 1] or 0
            C0 := Current[CurrentLen - 2] or 0

            if (C1 >= Floor(BASE / D1)) {
                return AdjustGuess(Current, Divisor, BASE - 1, UnsignedMulHandler(Divisor, BASE - 1))
            }
            
            DividendEstimate := (C1 * BASE) + C0
            Guess := Quotient[DividendEstimate, D1] or 0
            return AdjustGuess(Current, Divisor, Guess, UnsignedMulHandler(Divisor, Guess))
        }
        
        return AdjustGuess(Current, Divisor, BASE - 1, UnsignedMulHandler(Divisor, BASE - 1))
    }

    AdjustGuess<internal>(Current:[]int, Divisor:[]int, Guess:int, RoughProduct:[]int)<computes>:int = {
        Product := UnsignedSub(RoughProduct, Divisor)
        return not UnsignedGreatOrEqual(Current, RoughProduct)? and AdjustGuess(Current, Divisor, Guess - 1, Product) or Guess
    }

    ReverseLimbs<internal>(Limbs:[]int)<computes>:[]int = {
        return for (Index := 1..Limbs.Length, ReverseIndex := Limbs.Length - Index, Limb := Limbs[ReverseIndex]) do {
            Limb
        }
    }

    UnsignedDivModHandler<internal>(
        Dividend:[]int,
        Divisor:[]int,
        Index:int,
        CurrentRemainder:[]int,
        QuotientLimbs:[]int
    )<computes>:tuple([]int, []int) = {

        CurrentLimb := Dividend[Index] or 0

        ShiftedRemainder := CurrentRemainder.Length = 1 and CurrentRemainder[0] = 0 and array{0} or array{0} + CurrentRemainder

        TailOfRemainder := ShiftedRemainder.Slice[1] or array{}
        CurrentDividend := array{CurrentLimb} + TailOfRemainder
        TrimmedDividend := TrimZeros(CurrentDividend)
        
        QuotientLimb := FindQuotientLimb(TrimmedDividend, Divisor)
        
        NewQuotientLimbs := (QuotientLimbs.Length > 0 or QuotientLimb > 0) and QuotientLimbs + array{QuotientLimb} or QuotientLimbs

        Product := UnsignedMulHandler(Divisor, QuotientLimb)
        NewRemainder := UnsignedSub(TrimmedDividend, Product)

        return Index = 0 and (NewQuotientLimbs, NewRemainder) or (
            UnsignedDivModHandler(Dividend, Divisor, Index - 1, NewRemainder, NewQuotientLimbs)
        )
    }

    UnsignedDivMod<internal>(Dividend:[]int, Divisor:[]int)<computes>:tuple([]int, []int) = {
        Result := UnsignedDivModHandler(Dividend, Divisor, Dividend.Length - 1, array{0}, array{})

        BigEndianQuotient := Result(0)
        FinalRemainder := Result(1)
        
        ReversedQuotient := ReverseLimbs(BigEndianQuotient)
        
        FinalQuotient := ReversedQuotient.Length = 0 and array{0} or TrimZeros(ReversedQuotient)

        return (FinalQuotient, TrimZeros(FinalRemainder))
    }

    ToString<public>(Input:big_int)<computes>:string = {
        Parsed := Parse(Input)

        if (Parsed.Limbs.Length = 0 or Parsed.Limbs.Length = 1 and Parsed.Limbs[0] = 0) {
            return "0"
        }

        if {
            LastIndex := Parsed.Limbs.Length - 1
            FirstLimb := Parsed.Limbs[LastIndex] or 0
            
            OtherLimbs := Parsed.Limbs.Slice[0, LastIndex]
            
            RestString := Concatenate(
                for(Index := 1..OtherLimbs.Length) do {
                    Limb := OtherLimbs[OtherLimbs.Length - Index]
                    PadLimb("{Limb}")
                }
            )

            String := "{FirstLimb}" + RestString
        } then return Parsed.IsNegative? and "-" + String or String

        return "0"
    }

    FromInt<public>(Value:int)<computes>:big_int = {
        return Parse(big_int{Value := "{ToString(Value)}"})
    }

    Equal<public>(Left:big_int, Right:big_int)<computes><decides>:void = {
        Left.IsNegative = Right.IsNegative
        Left.Limbs.Length = Right.Limbs.Length
        for(Index := 0..Left.Limbs.Length - 1) do Left.Limbs[Index] = Right.Limbs[Index]
    }

    Great<public>(Left:big_int, Right:big_int)<computes><decides>:void = {
        not Left.IsNegative? and Right.IsNegative? or
        not Left.IsNegative? and (Left.Limbs.Length > Right.Limbs.Length or Left.Limbs.Length = Right.Limbs.Length and GreatHandler(Left, Right)?) or
        Left.IsNegative? and (Left.Limbs.Length < Right.Limbs.Length or Left.Limbs.Length = Right.Limbs.Length and GreatHandler(Right, Left)?)
    }

    Small<public>(Left:big_int, Right:big_int)<computes><decides>:void = {
        Great[Right, Left]
    }

    operator'+'<public>(Left:big_int, Right:big_int)<computes>:big_int = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)

        if (LParsed.IsNegative = RParsed.IsNegative) then {
            return big_int {
                Limbs := UnsignedAdd(LParsed.Limbs, RParsed.Limbs)
                IsNegative := LParsed.IsNegative
            }
        }

        AbsLeft := big_int {Limbs := LParsed.Limbs, IsNegative := false}
        AbsRight := big_int {Limbs := RParsed.Limbs, IsNegative := false}

        Result := Great[AbsLeft, AbsRight] and (UnsignedSub(LParsed.Limbs, RParsed.Limbs), LParsed.IsNegative) or
                  Small[AbsLeft, AbsRight] and (UnsignedSub(RParsed.Limbs, LParsed.Limbs), RParsed.IsNegative) or
                  (array{0}, false)

        return big_int {
            Limbs := Result(0)
            IsNegative := Result(1)
        }
    }

    operator'-'<public>(Left:big_int, Right:big_int)<computes>:big_int = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)
        FlippedRight := big_int { Limbs := RParsed.Limbs, IsNegative := not RParsed.IsNegative? and true or false}
        return LParsed + FlippedRight
    }

    operator'*'<public>(Left:big_int, Right:big_int)<computes>:big_int = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)
        Limbs := UnsignedMul(LParsed.Limbs, RParsed.Limbs)
        IsNegative := LParsed.IsNegative <> RParsed.IsNegative and true or false
        return big_int {Limbs := Limbs, IsNegative := IsNegative}
    }

    operator'/'<public>(Left:big_int, Right:big_int)<computes>:big_int = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)

        # 1. Check for division by zero
        if (RParsed.Limbs.Length = 1 and RParsed.Limbs[0] = 0) {
            Err("ERROR: Division by zero")
            return big_int{} # Or use panic()
        }

        # 2. Check if dividend is zero
        if (LParsed.Limbs.Length = 1 and LParsed.Limbs[0] = 0) {
            return big_int{Limbs := array{0}, IsNegative := false}
        }

        # 3. Compare absolute values
        AbsLeft := LParsed.Limbs
        AbsRight := RParsed.Limbs
        
        if (not UnsignedGreatOrEqual(AbsLeft, AbsRight)?) {
            # |Left| < |Right|, so quotient is 0
            return big_int{Limbs := array{0}, IsNegative := false}
        }

        # 4. Perform unsigned division
        Result := UnsignedDivMod(AbsLeft, AbsRight)
        ResultQuotient := Result(0)
        ResultRemainder := Result(1)

        # 5. Determine sign
        IsNegative := LParsed.IsNegative <> RParsed.IsNegative and true or false

        return big_int {
            Limbs := ResultQuotient
            IsNegative := IsNegative
        }
    }

    Mod<public>(Left:big_int, Right:big_int)<computes>:big_int = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)

        if (RParsed.Limbs.Length = 1 and RParsed.Limbs[0] = 0) {
            Err("ERROR: Modulo by zero")
            return big_int{} # Or use panic()
        }

        if (LParsed.Limbs.Length = 1 and LParsed.Limbs[0] = 0) {
            return big_int{Limbs := array{0}, IsNegative := false}
        }

        AbsLeft := LParsed.Limbs
        AbsRight := RParsed.Limbs

        if (not UnsignedGreatOrEqual(AbsLeft, AbsRight)?) {
            return LParsed
        }

        Result := UnsignedDivMod(AbsLeft, AbsRight)
        ResultQuotient := Result(0)
        ResultRemainder := Result(1)

        return big_int {
            Limbs := ResultRemainder
            IsNegative := LParsed.IsNegative
        }
    }

    Mod<public>(Left:big_int, Right:int):big_int = {
        return Mod(Left, FromInt(Right))
    }

    operator'+'<public>(Left:big_int, Right:int)<computes>:big_int = Left + FromInt(Right)
    operator'-'<public>(Left:big_int, Right:int)<computes>:big_int = Left - FromInt(Right)
    operator'*'<public>(Left:big_int, Right:int)<computes>:big_int = Left * FromInt(Right)
    operator'/'<public>(Left:big_int, Right:int)<computes>:big_int = Left / FromInt(Right)

    operator'+'<public>(Left:int, Right:big_int)<computes>:big_int = FromInt(Left) + Right
    operator'-'<public>(Left:int, Right:big_int)<computes>:big_int = FromInt(Left) - Right
    operator'*'<public>(Left:int, Right:big_int)<computes>:big_int = FromInt(Left) * Right
    operator'/'<public>(Left:int, Right:big_int)<computes>:big_int = FromInt(Left) / Right

    # big_int_test_component := class<final_super>(component) {
    #     @editable
    #     FirstNumber:big_int = big_int {}

    #     @editable
    #     SecondNumber:big_int = big_int {}

    #     @editable
    #     ParseTest:int = 12345

    #     OnBeginSimulation<override>():void = {
    #         (super:)OnBeginSimulation()

    #         Print(ToString(Parse(FromInt(ParseTest))))

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
