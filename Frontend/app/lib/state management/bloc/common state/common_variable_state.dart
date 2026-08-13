part of 'common_variable_bloc.dart';

@immutable
class CommonVariableState extends Equatable{

  int? counter;

  CommonVariableState({this.counter=0});

  CommonVariableState copyWith({int? counter}){
    return
      CommonVariableState(
          counter: counter ?? this.counter
      );
  }

  @override
  List<Object?> get props => [counter];

}

