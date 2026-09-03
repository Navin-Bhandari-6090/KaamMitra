part of 'common_variable_bloc.dart';

@immutable
class CommonVariableState extends Equatable{

  String? Role;
  bool? ObscureValuePassword;
  bool? ObscureValueRetypePassword;
  String? ProviderServiceName;


  CommonVariableState({this.Role="User",this.ObscureValuePassword=true,this.ObscureValueRetypePassword=true,this.ProviderServiceName=""});

  CommonVariableState copyWith({String? Role,bool? ObscureValue,bool? ObscureValueRetypePassword,String? ProviderServiceName}){
    return
      CommonVariableState(
          Role: Role ?? this.Role,
          ObscureValuePassword: ObscureValue ?? this.ObscureValuePassword,
          ObscureValueRetypePassword: ObscureValueRetypePassword ?? this.ObscureValueRetypePassword,
          ProviderServiceName: ProviderServiceName ?? this.ProviderServiceName
      );
  }

  @override
  List<Object?> get props => [Role,ObscureValuePassword,ObscureValueRetypePassword,ProviderServiceName];

}

