import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
// Adjust to your ambient background file location.
import '../../../state management/getx/profile/provider/add_notice_getx.dart';
import '../../common method/ui_kit.dart';
import '../../common widget/design/bolbs_background.dart';


class AddNotice extends StatelessWidget {
  final String Current_User_JwtToken;

  const AddNotice({super.key, required this.Current_User_JwtToken});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddNoticeGetx>(
      init: AddNoticeGetx(jwtToken: Current_User_JwtToken),
      builder: (c) => Scaffold(
        backgroundColor: AppColors.body,
        body: Stack(
          children: [
            const Positioned.fill(child: AmbientBackground()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  final double pad = AppResponsive.horizontalPadding(width);
                  final bool wide = AppResponsive.isWide(width);

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: pad, vertical: 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: AppResponsive.contentMaxWidth(width),
                        ),
                        child: FadeSlideIn(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _Header(controller: c),
                              const SizedBox(height: 28),
                              if (wide)
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: _FormCard(controller: c),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 2,
                                        child: _PreviewCard(controller: c),
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                _FormCard(controller: c),
                                const SizedBox(height: 20),
                                _PreviewCard(controller: c),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final AddNoticeGetx controller;

  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool canGoBack = Navigator.of(context).canPop();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (canGoBack) ...[
              const BorderedBackButton(),
              const SizedBox(width: 16),
            ],
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Notice',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Write a notice for one of your services',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 15),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Obx(
              () => controller.isVerifying.value
              ? const LinearProgressIndicator(
            minHeight: 3,
            color: AppColors.accent,
            backgroundColor: AppColors.border,
          )
              : const SizedBox(height: 3),
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final AddNoticeGetx controller;

  const _FormCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionLabel('Service'),
            const SizedBox(height: 10),
            TextFormField(
              controller: controller.serviceIdController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: AppColors.primaryText),
              cursorColor: AppColors.accent,
              validator: controller.validateServiceId,
              decoration: _inputDecoration(
                label: 'Service ID',
                hint: 'e.g. 12',
                icon: Icons.design_services_outlined,
              ),
            ),
            const SizedBox(height: 24),
            const _SectionLabel('Notice message'),
            const SizedBox(height: 10),
            TextFormField(
              controller: controller.messageController,
              minLines: 4,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(color: AppColors.primaryText, height: 1.5),
              cursorColor: AppColors.accent,
              validator: controller.validateMessage,
              decoration: _inputDecoration(
                label: 'Message',
                hint: 'Write your notice here...',
                icon: Icons.notes_rounded,
                alignLabelWithHint: true,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Obx(
                      () => Text(
                    '${controller.message.value.length} characters',
                    style: const TextStyle(
                      color: AppColors.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _SubmitButton(controller: controller),
          ],
        ),
      ),
    );
  }

  static InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: Icon(icon, color: AppColors.mutedText, size: 20),
      labelStyle: const TextStyle(color: AppColors.mutedText),
      floatingLabelStyle: const TextStyle(color: AppColors.accent),
      hintStyle: TextStyle(color: AppColors.mutedText.withOpacity(0.6)),
      errorStyle: const TextStyle(color: AppColors.danger),
      filled: true,
      fillColor: AppColors.body.withOpacity(0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(AppColors.border),
      enabledBorder: border(AppColors.border),
      focusedBorder: border(AppColors.accent, 1.6),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.6),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final AddNoticeGetx controller;

  const _SubmitButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool busy = controller.isSubmitting.value;

      return SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.body,
            disabledBackgroundColor: AppColors.accent.withOpacity(0.4),
            disabledForegroundColor: AppColors.body,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: busy ? null : controller.submitNotice,
          child: busy
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.body,
            ),
          )
              : const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.send_rounded, size: 18),
              SizedBox(width: 8),
              Text(
                'Add notice',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _PreviewCard extends StatelessWidget {
  final AddNoticeGetx controller;

  const _PreviewCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('Live preview'),
          const SizedBox(height: 16),
          Obx(() {
            final int id = controller.serviceId.value;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
              ),
              child: Text(
                id > 0 ? 'Service #$id' : safeText(null),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.body.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Obx(() {
              final String text = controller.message.value.trim();
              return Text(
                safeText(text),
                style: TextStyle(
                  color: text.isEmpty
                      ? AppColors.mutedText
                      : AppColors.primaryText,
                  fontSize: 16,
                  height: 1.5,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.mutedText, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Review the message. You will be asked to confirm before it is added.',
                  style: TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.mint,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}