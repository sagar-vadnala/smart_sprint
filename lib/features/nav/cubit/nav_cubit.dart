import 'package:flutter_bloc/flutter_bloc.dart';

/// Bottom-nav tab index. 0=Home, 1=Spaces, 2=My Tasks, 3=Inbox.
class NavCubit extends Cubit<int> {
  NavCubit() : super(0);

  void select(int index) => emit(index);
}
