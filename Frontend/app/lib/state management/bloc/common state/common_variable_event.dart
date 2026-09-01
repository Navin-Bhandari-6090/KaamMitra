part of 'common_variable_bloc.dart';

@immutable
abstract class CommonVariableEvent extends Equatable {
  CommonVariableEvent();
  @override
  List<Object> get props=>[];

}

class SelectUserRole extends CommonVariableEvent
{
  final String? Role;
  SelectUserRole({required this.Role});
  @override
  List<Object> get props=>[Role!];

}

class ChangeObscureValuePassword extends CommonVariableEvent
{

}

class ChangeObscureValueRetypePassword extends CommonVariableEvent
{

}

class SelectProviderSerrviceName extends CommonVariableEvent
{
  final String? ProviderSerrviceName ;
  SelectProviderSerrviceName({required this.ProviderSerrviceName});
  @override
  List<Object> get props=>[ProviderSerrviceName!];

}


