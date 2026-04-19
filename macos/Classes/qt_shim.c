// Forwarder — CocoaPods' source_files glob can't reach outside the podspec's
// directory, so we relatively include the actual sources under `../native/`.
// See ../quicktype_dart.podspec for details.
#include "../../native/shim/qt_shim.c"
