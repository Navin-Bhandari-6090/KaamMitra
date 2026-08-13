import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';


part 'common_variable_event.dart';
part 'common_variable_state.dart';


class CommonVariableBloc extends Bloc<CommonVariableEvent, CommonVariableState>
{


  CommonVariableBloc() : super(CommonVariableState()) {

    on<Increment>(_increment);
    on<Decrement>(_decrement);

  }

  void _increment(Increment event,Emitter<CommonVariableState> emit){

    emit(state.copyWith(counter: state.counter! + 1));

  }

  void _decrement(Decrement event,Emitter<CommonVariableState> emit){
    emit(state.copyWith(counter: state.counter! - 1));
  }

}




