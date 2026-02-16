using { /Verse.org/SceneGraph }

FidgetStateMachine := module:
    using { /Verse.org/Simulation }

    execution_function<internal>:= type{_():void}
    condition_function<internal>:= type{_()<transacts><decides>:void}

    transition_functions<public>:= struct<concrete><computes><internal>:
        (transition_functions:)MaybeExecution:?execution_function = false
        (transition_functions:)MaybeCondition:?condition_function = false

    transition<public> := struct<concrete><computes><internal>:
        (transition:)Event:?comparable = false
        (transition:)State:comparable = false
        (transition:)Executions:[]execution_function = array{}
        (transition:)Conditions:[]condition_function = array{}
    
    state<public>:= struct<concrete><computes><internal>:
        (state:)Final:logic = false
        (state:)Transitions:[comparable][]transition = map{}
        (state:)Immediates:?[]transition = false
        (state:)OnEnter:?type{_()<suspends>:void} = false

    machine<public>:= event(comparable)

    InternalState<internal>(OnEnter:?type{_()<suspends>:void}, Transitions:[]transition):state =
        var TransitionsMap:[comparable][]transition = map{}
        for (_Transition : Transitions, Event := _Transition.Event?, set TransitionsMap[Event] += array {_Transition}) do {}

        Immediates := option {for (_Transition : Transitions, not _Transition.Event?) do _Transition}

        return state {
            Final := Transitions.Length = 0 and true or false
            Transitions := TransitionsMap
            Immediates := Immediates
            OnEnter := OnEnter
        }
    
    InternalTransition<internal>(InEvent:?event_t, InState:state_t, InFunctions:[]transition_functions where event_t:subtype(comparable), state_t:subtype(comparable)):transition =
        Executions := for (Function : InFunctions, ExecutionFunction := Function.MaybeExecution?) do ExecutionFunction
        Conditions := for (Function : InFunctions, ConditionFunction := Function.MaybeCondition?) do ConditionFunction

        return transition {
            Event := InEvent
            State := InState
            Executions := Executions
            Conditions := Conditions
        }

    InternalTryTransition<internal>(InState:state, States:[comparable]state)<suspends>:state =
        if (Immediates := InState.Immediates?) then:
            for:
                _Immediate : Immediates
                Passed  := for (_Condition : _Immediate.Conditions, _Condition[]) do void
                Passed.Length = _Immediate.Conditions.Length
                NewState := States[_Immediate.State]
            do:
                Sleep(0.0)
                for (_Execute : _Immediate.Executions) do _Execute()
                return InternalTryTransition(NewState, States)
        
        return InState

    InternalWaitTransition<internal>(Machine:machine, InState:?state, States:[comparable]state)<suspends>:?state =
        Result := Machine.Await()

        if (Transitions := InState?.Transitions[Result]) then:
            for:
                _Transition : Transitions
                Passed  := for (_Condition : _Transition.Conditions, _Condition[]) do void
                Passed.Length = _Transition.Conditions.Length
                NewState := States[_Transition.State]
            do:
                for (_Execute : _Transition.Executions) do _Execute()
                return option {NewState}
        
        return InState

    (Machine:machine).Run<public>(Initial:state_t, States:[state_t]state where state_t:subtype(comparable))<suspends>:void =
        var CurrentState:?state = false

        if (InitialState := States[Initial]) then:
            NewState := InternalTryTransition(InitialState, States)
            set CurrentState = option {NewState}
        
        loop:
            if (_State := CurrentState?, not _State.Final?) then:
                if (OnEnter := _State.OnEnter?) then race:
                    block:
                        OnEnter()
                        Machine.Signal("Done")
                    block:
                        InternalWaitTransition(Machine, CurrentState, States)
                        Machine.Signal("Canceled")
                else:
                    InternalWaitTransition(Machine, CurrentState, States)
            else break
    
    State<public>(InTransitions:[]transition):state =
        return InternalState(false, InTransitions)

    State<public>(InTransition:transition):state =
        return InternalState(false, array {InTransition})

    Invoke<public>(OnEnter:type{_()<suspends>:void}, InTransitions:[]transition):state =
        return InternalState(option {OnEnter}, InTransitions)

    Invoke<public>(OnEnter:type{_()<suspends>:void}, InTransition:transition):state =
        return InternalState(option {OnEnter}, array {InTransition})

    Transition<public>(InEvent:comparable, InState:comparable, InFunctions:[]transition_functions):transition =
        return InternalTransition(option {InEvent}, InState, InFunctions)
    
    Transition<public>(InEvent:comparable, InState:comparable, InFunction:transition_functions):transition =
        return InternalTransition(option {InEvent}, InState, array {InFunction})

    Transition<public>(InEvent:comparable, InState:comparable):transition =
        return InternalTransition(option {InEvent}, InState, array {})

    Immediate<public>(InState:comparable, InFunctions:[]transition_functions):transition =
        return InternalTransition(false, InState, InFunctions)

    Immediate<public>(InState:comparable, InFunction:transition_functions):transition =
        return InternalTransition(false, InState, array {InFunction})

    Immediate<public>(InState:comparable):transition =
        return InternalTransition(false, InState, array {})
    
    Execute<public>(Function:execution_function):transition_functions =
        return transition_functions {MaybeExecution := option {Function}}

    Condition<public>(Function:condition_function):transition_functions =
        return transition_functions {MaybeCondition := option {Function}}

    test_component := class<final_super>(component) {

        Machine:machine = machine{}

        OnSimulate<override>()<suspends>:void =
            Machine.Run("Idle", map {
                "Idle" => State(
                    Transition("Toggle", "Walk", (
                        Execute(OnWalk)
                        Condition(OnWalkCondition)
                    ))
                )
            })
        
        OnWalk():void = {}
        OnWalkCondition()<transacts><decides>:void = {}
    }