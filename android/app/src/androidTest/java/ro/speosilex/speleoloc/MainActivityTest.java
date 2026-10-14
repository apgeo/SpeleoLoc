package ro.speosilex.speleoloc;

import androidx.test.rule.ActivityTestRule;
import dev.flutter.plugins.integration_test.FlutterTestRunner;
import org.junit.Rule;
import org.junit.runner.RunWith;

/**
 * Runs the Dart integration tests as an Android instrumentation, which is
 * how a cloud device lab (Firebase Test Lab) runs them: it installs the app
 * and this test APK and reports each Dart test as a JUnit result. Locally
 * the tests go through `flutter drive` instead; see tool/android/run_cell.sh.
 */
@RunWith(FlutterTestRunner.class)
public class MainActivityTest {
  @Rule
  public ActivityTestRule<MainActivity> rule =
      new ActivityTestRule<>(MainActivity.class, true, false);
}
