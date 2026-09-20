// Point d'entrée de l'intégration Health Connect.
//
// Le paquet `health` (et `dart:io`) ne compilent pas sur le web. On sélectionne
// donc l'implémentation réelle uniquement quand `dart:io` est disponible
// (Android/iOS/desktop) ; le web reçoit un stub no-op.
export 'health_service_stub.dart'
    if (dart.library.io) 'health_service_io.dart';
