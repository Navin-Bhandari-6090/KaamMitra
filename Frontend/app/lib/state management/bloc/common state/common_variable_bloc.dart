import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
part 'common_variable_event.dart';
part 'common_variable_state.dart';


class CommonVariableBloc extends Bloc<CommonVariableEvent, CommonVariableState>
{


  CommonVariableBloc() : super(CommonVariableState()) {

    on<SelectUserRole>(Select_User_Role);
    on<ChangeObscureValuePassword>(Change_Obscure_Value);
    on<ChangeObscureValueRetypePassword>(Change_Obscure_Value_Retype_Password);
    on<SelectProviderSerrviceName>(Select_Provider_Serrvice_Name);

  }

  void Select_User_Role(SelectUserRole event,Emitter<CommonVariableState> emit){

    emit(state.copyWith(Role: event.Role));

  }

  void Change_Obscure_Value(ChangeObscureValuePassword event,Emitter<CommonVariableState> emit){

    emit(state.copyWith(ObscureValue: !state.ObscureValuePassword!));

  }

  void Change_Obscure_Value_Retype_Password(ChangeObscureValueRetypePassword event,Emitter<CommonVariableState> emit){

    emit(state.copyWith(ObscureValueRetypePassword: !state.ObscureValueRetypePassword!));

  }

  void Select_Provider_Serrvice_Name(SelectProviderSerrviceName event,Emitter<CommonVariableState> emit){

    emit(state.copyWith(ProviderServiceName: event.ProviderSerrviceName));

  }




}




