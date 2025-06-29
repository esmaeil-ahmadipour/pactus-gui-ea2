import 'package:fluent_ui/fluent_ui.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:pactus_gui/src/core/common/widgets/app_layout.dart';
import 'package:pactus_gui/src/core/router/route_name.dart';
import 'package:pactus_gui/src/core/utils/gen/assets/assets.gen.dart';
import 'package:pactus_gui/src/core/utils/gen/localization/locale_keys.dart';
import 'package:pactus_gui/src/features/main/language/core/localization_extension.dart';
import 'package:pactus_gui_widgetbook/app_core.dart';
import 'package:pactus_gui_widgetbook/app_styles.dart';
import 'package:pactus_gui_widgetbook/app_widgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      content: NavigationView(
        content: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  Assets.images.welcomePic.path,
                  width: double.infinity,
                  height: 459,
                ),
                const Gap(40),
                Text(
                  context.tr(LocaleKeys.welcome_title),
                  style: InterTextStyles.bodyStrong.copyWith(
                    color: AppTheme.of(
                      context,
                    ).extension<DarkPallet>()!.dark900,
                  ),
                ),
                const Gap(16),
                Text(
                  context.tr(LocaleKeys.welcome_description),
                  style: InterTextStyles.body.copyWith(
                    color: AppTheme.of(
                      context,
                    ).extension<DarkPallet>()!.dark900,
                  ),
                  softWrap: true,
                  textAlign: TextAlign.center,
                ),
                const Gap(16),
                IntrinsicWidth(
                  child: SizedBox(
                    height: 32,
                    child: AdaptivePrimaryButton.createTitleOnly(
                      onPressed: () {
                        context.go(
                          '${AppRoute.welcome.fullPath}/${AppRoute.initializeMode.path}',
                        );
                      },
                      requestState: RequestStateEnum.loaded,
                      title: context.tr(LocaleKeys.start_button_text),
                    ),
                  ),
                ),
                const Gap(50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
