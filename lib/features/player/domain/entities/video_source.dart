import 'package:equatable/equatable.dart';

class VideoSource extends Equatable {
  const VideoSource({
    required this.smbPath,
    required this.title,
    required this.connectionId,
  });

  final String smbPath;
  final String title;
  final String connectionId;

  @override
  List<Object?> get props => <Object?>[smbPath, title, connectionId];
}
