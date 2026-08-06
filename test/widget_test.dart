import 'package:bmc_app/core/network/provider/widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bmc_app/features/common/widget.dart'; // BMCRouter
import 'package:bmc_app/main.dart';

void main() {
  testWidgets('App builds and renders without crashing', (WidgetTester tester) async {
    // BMCRouter() runs the same one-time router setup main() does before
    // build() reads BMCRouter.router — without this, the widget tree throws
    // on the very first pump.
    BMCRouter();

    final userProvider = UserProvider();
    await tester.pumpWidget(BMCStaffSelfService(userProvider: userProvider));
    await tester.pump();

    // Replace with something real once you settle on what the very first
    // frame should show — e.g. if BMCRouter's initial route is the login
    // screen:
    // expect(find.text('LOGIN PORTAL'), findsOneWidget);
  });
}
