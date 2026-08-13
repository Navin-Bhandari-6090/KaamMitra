part of 'common_variable_bloc.dart';

@immutable
abstract class CommonVariableEvent extends Equatable {
  CommonVariableEvent();
  @override
  List<Object> get props=>[];

}

class Increment extends CommonVariableEvent
{

}

class Decrement extends CommonVariableEvent
{

}
