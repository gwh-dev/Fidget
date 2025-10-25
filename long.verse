using { /UnrealEngine.com/JSON }
using { /Verse.org/SceneGraph }
using { /Verse.org/Simulation }

Long<public>:= module {

    BASE<internal>:int = 1000000000
    BASE_DIGITS<internal>:int = 9

    long<public>:= struct<persistable><computes><concrete>{
        @editable
        Value:string = array{}
        LongNumber:[]int = array{}
        IsNegative:logic = false
    }

    # --- Internal Helper Functions ---

    Parse<internal>(Input:long)<computes>:long = {
        if (Input.Value.Length = 0) then return Input

        NumbString := Input.Value[0] = '-' and Input.Value.Slice[1] or Input.Value
        IsNegative := Input.Value[0] = '-' and true or false
        LongNumber := for {
            Index := 0..NumbString.Length
            EndIndex := NumbString.Length - Index
            StartIndex := Max(0, EndIndex - BASE_DIGITS)
            ChunkString := NumbString.Slice[StartIndex, EndIndex - 1]
        }do ChunkToInt(ChunkString, 0, 0)

        return long {
            LongNumber := LongNumber
            IsNegative := IsNegative
        }
    }

    ChunkToInt<internal>(Input:string, Index:int, Num:int)<computes>:int = {
        return ChunkToInt(Input, Index + 1, Num * 10 + case(Input[Index]) {
            '0' => 0; '1' => 1; '2' => 2
            '3' => 3; '4' => 4; '5' => 5
            '6' => 6; '7' => 7; '8' => 8
            '9' => 9

            _ => Err("ERROR: long value are unvalid")
        }) or Num
    }

    GreatHandler<internal>(Left:long, Right:long)<computes>:logic = {
        for(Index := 1..Left.LongNumber.Length, CurrentIndex := Left.LongNumber.Length - Index) do {
            if (Left.LongNumber[CurrentIndex] > Right.LongNumber[CurrentIndex]) then return true
            if (Left.LongNumber[CurrentIndex] < Right.LongNumber[CurrentIndex]) then return false
        }
        return false
    }

    TrimZeros<internal>(Input:[]int)<computes>:[]int = {
        if (Input.Length <= 1) then return Input
        LastChunk := Input[Input.Length-1] or Err()
        return LastChunk = 0 and TrimZeros(Input.Slice[0, Input.Length - 2]) or Input
    }

    UnsignedAdd<internal>(Left:[]int, Right:[]int, ?Carry:int = 0)<computes>:[]int = {
        LChunk := Left[0] or 0
        RChunk := Right[0] or 0

        LTail := Left.Slice[1] or ()
        RTail := Right.Slice[1] or ()

        Total := LChunk + RChunk + Carry
        Digit := Mod[Total, BASE] or Err()
        Extra := Floor(Total / BASE) or Err()

        RemainingChunks := UnsignedAdd(LTail, RTail, ?Carry := Extra)

        return array{Digit} + RemainingChunks
    }

    UnsignedSub<internal>(Left:[]int, Right:[]int)<computes>:[]int = {
        RawResult := UnsignedSubHandler(Left, Right)
        return TrimZeros(RawResult)
    }

    UnsignedSubHandler<internal>(Left:[]int, Right:[]int, ?Borrow:int = 0)<computes>:[]int = {
        LChunk := Left[0] or 0
        RChunk := Right[0] or 0

        LTail := Left.Slice[1] or ()
        RTail := Right.Slice[1] or ()

        Diff := LChunk - RChunk - Borrow
        Digit := Diff < 0 and Diff + BASE or Diff
        Extra := Diff < 0 and 1 or 0

        RemainingChunks := UnsignedSubHandler(LTail, RTail, ?Borrow := Extra)

        return array{Digit} + RemainingChunks
    }

    UnsignedMul<internal>(Left:[]int, Right:[]int)<computes>:[]int = {
        if (Left.Length = 1 and Left[0] = 0 or Right.Length = 1 and Right[0] = 0) then {
            return array{0}
        }

        RawMaxLength := Max(Left.Length, Right.Length)
        MaxLength := Mod[RawMaxLength, 2] = 1 and RawMaxLength + 1 or RawMaxLength

        LPadded := Left + for(__:=0..MaxLength - Left.Length) do 0
        RPadded := Right + for(__:=0..MaxLength - Right.Length) do 0

        Middle := Floor(MaxLength / 2) or Err("ERROR: multiplication middle point are unvalid.")

        B := LPadded.Slice[0, Middle]   or Err()
        A := LPadded.Slice[Middle]      or Err()
        D := RPadded.Slice[0, Middle]   or Err()
        C := RPadded.Slice[Middle]      or Err()

        P1 := UnsignedMul(A, C)
        P2 := UnsignedMul(B, D)

        APlusB := UnsignedAdd(A, B)
        CPlusD := UnsignedAdd(C, D)

        P3 := UnsignedMul(APlusB, CPlusD)

        MiddleTerm := UnsignedSub(UnsignedSub(P3, P1), P2)

        P1Shifted := (for(__:= 0..(2*Middle)) do 0) + P1

        MiddleTermShifted := (for(__:= 0..Middle) do 0) + MiddleTerm

        Result := UnsignedAdd(UnsignedAdd(P1Shifted, MiddleTermShifted), P2)

        return TrimZeros(Result)
    }

    # --- Public Helper Functions ---

    ToString<public>(Input:long)<computes>:string = {
        Parsed := Parse(Input)
        Length := Parsed.LongNumber.Length
        String := Concatenate(for(Index := 1..Length, Digit := Parsed.LongNumber[Length - Index]) do "{Digit}")
        return Parsed.IsNegative? and "-" + String or String
    }

    FromInt<public>(Value:int)<computes>:long = {
        return Parse(long{Value := "{ToString(Value)}"})
    }

    Equal<public>(Left:long, Right:long)<computes><decides>:void = {
        Left.IsNegative = Right.IsNegative
        Left.LongNumber.Length = Right.LongNumber.Length
        for(Index := 0..Left.LongNumber.Length - 1) do Left.LongNumber[Index] = Right.LongNumber[Index]
    }

    Great<public>(Left:long, Right:long)<computes><decides>:void = {
        not Left.IsNegative? and Right.IsNegative? or
        not Left.IsNegative? and Left.LongNumber.Length > Right.LongNumber.Length or GreatHandler(Left, Right)?
        Left.IsNegative? and Left.LongNumber.Length < Right.LongNumber.Length or GreatHandler(Right, Left)?
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
                LongNumber := UnsignedAdd(LParsed.LongNumber, RParsed.LongNumber)
                IsNegative := LParsed.IsNegative
            }
        }

        AbsLeft := long {LongNumber := LParsed.LongNumber, IsNegative := false}
        AbsRight := long {LongNumber := RParsed.LongNumber, IsNegative := false}

        Result := Great[AbsLeft, AbsRight] and (UnsignedSub(LParsed.LongNumber, RParsed.LongNumber), LParsed.IsNegative) or
                  Small[AbsLeft, AbsRight] and (UnsignedSub(RParsed.LongNumber, LParsed.LongNumber), RParsed.IsNegative) or
                  (array{0}, false)

        return long {
            LongNumber := Result(0)
            IsNegative := Result(1)
        }
    }

    operator'-'<public>(Left:long, Right:long)<computes>:long = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)
        FlippedRight := long { LongNumber := RParsed.LongNumber, IsNegative := not RParsed.IsNegative? and true or false}
        return LParsed + FlippedRight
    }

    operator'*'<public>(Left:long, Right:long)<computes>:long = {
        LParsed := Parse(Left)
        RParsed := Parse(Right)
        LongNumber := UnsignedMul(LParsed.LongNumber, RParsed.LongNumber)
        IsNegative := LParsed.IsNegative <> RParsed.IsNegative and true or false
        return long {LongNumber := LongNumber, IsNegative := IsNegative}
    }

    operator'/'<public>(Left:long, Right:long)<computes>:long = long{}

    operator'+'<public>(Left:long, Right:int)<computes>:long = Left + FromInt(Right)
    operator'-'<public>(Left:long, Right:int)<computes>:long = Left - FromInt(Right)
    operator'*'<public>(Left:long, Right:int)<computes>:long = Left * FromInt(Right)
    operator'/'<public>(Left:long, Right:int)<computes>:long = Left / FromInt(Right)

    operator'+'<public>(Left:int, Right:long)<computes>:long = FromInt(Left) + Right
    operator'-'<public>(Left:int, Right:long)<computes>:long = FromInt(Left) + Right
    operator'*'<public>(Left:int, Right:long)<computes>:long = FromInt(Left) + Right
    operator'/'<public>(Left:int, Right:long)<computes>:long = FromInt(Left) + Right
}
