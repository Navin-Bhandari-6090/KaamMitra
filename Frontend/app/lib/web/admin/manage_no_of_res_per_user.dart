
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Adjust these paths to where the files are saved in your project.
import 'package:app/web/common%20widget/design/bolbs_background.dart';

import '../../../models/NoOFResoucesPerUserModel.dart';
import '../../state management/getx/admin/manage_no_of_res_per_user_getx.dart';
import '../common method/ui_kit.dart';
import '../common widget/GreenTextfield.dart';


class ManageNoOfResPerUser extends StatelessWidget {
  final String User_JwtToken;

  const ManageNoOfResPerUser({super.key, required this.User_JwtToken});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ManageNoOfResPerUserGetx>(
      init: ManageNoOfResPerUserGetx(jwtToken: User_JwtToken),
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
                              const SizedBox(height: 24),
                              _AddForm(controller: c),
                              const SizedBox(height: 28),
                              _ListHeader(controller: c),
                              const SizedBox(height: 14),
                              _ResourceList(controller: c),
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
  final ManageNoOfResPerUserGetx controller;

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
                    'Resource Limits',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Set how many resources each user can use per service',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _RefreshButton(onTap: () => controller.fetchResources()),
          ],
        ),
        const SizedBox(height: 14),
        Obx(
              () => controller.isLoading.value
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

class _RefreshButton extends StatelessWidget {
  final VoidCallback onTap;

  const _RefreshButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Refresh resource limits',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primaryText.withOpacity(0.55),
                width: 1.4,
              ),
            ),
            child: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primaryText,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddForm extends StatelessWidget {
  final ManageNoOfResPerUserGetx controller;

  const _AddForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionLabel('New resource limit'),
          const SizedBox(height: 18),
          GreenField(
            controller: controller.serviceNameController,
            label: 'Service name',
            icon: Icons.design_services_outlined,
          ),
          const SizedBox(height: 16),
          GreenField(
            controller: controller.userNumberController,
            label: 'User number',
            icon: Icons.person_outline_rounded,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          GreenField(
            controller: controller.noOfResController,
            label: 'Number of resources',
            icon: Icons.inventory_2_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
          _AddButton(controller: controller),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  final ManageNoOfResPerUserGetx controller;

  const _AddButton({required this.controller});

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
          onPressed: busy ? null : controller.submitAdd,
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
              Icon(Icons.add_circle_outline_rounded, size: 20),
              SizedBox(width: 8),
              Text(
                'Add limit',
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

class _ListHeader extends StatelessWidget {
  final ManageNoOfResPerUserGetx controller;

  const _ListHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: _SectionLabel('Current limits')),
        Obx(
              () => Text(
            '${controller.resourcesList.length} total',
            style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

class _ResourceList extends StatelessWidget {
  final ManageNoOfResPerUserGetx controller;

  const _ResourceList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.resourcesList.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        );
      }

      if (controller.errorMessage.value != null &&
          controller.resourcesList.isEmpty) {
        return _ErrorState(
          message: controller.errorMessage.value!,
          onRetry: () => controller.fetchResources(),
        );
      }

      if (controller.resourcesList.isEmpty) {
        return const DataNotAvailable(
          message: 'Data not available',
          icon: Icons.inventory_2_outlined,
        );
      }

      return LayoutBuilder(
        builder: (context, box) {
          final bool twoColumns = box.maxWidth >= 720;
          final double cardWidth =
          twoColumns ? (box.maxWidth - 20) / 2 : box.maxWidth;

          return Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              for (final item in controller.resourcesList)
                SizedBox(
                  key: ValueKey(item.resourcesNumberId),
                  width: cardWidth,
                  child: _ResourceCard(controller: controller, item: item),
                ),
            ],
          );

        },
      );
    });
  }
}

class _ResourceCard extends StatelessWidget {
  final ManageNoOfResPerUserGetx controller;
  final NoOfResoucesPerUserModel item;

  const _ResourceCard({required this.controller, required this.item});

  @override
  Widget build(BuildContext context) {
    final int? id = item.resourcesNumberId?.toInt();
    final int? count = item.noOfRes?.toInt();
    final int? userNumber = item.userNumber?.toInt();

    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safeText(item.serviceName),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _Chip(
                      label: userNumber != null
                          ? 'User #$userNumber'
                          : safeText(null),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CountBox(value: count),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  id != null ? 'Limit ID #$id' : safeText(null),
                  style: const TextStyle(
                    color: AppColors.mutedText,
                    fontSize: 13,
                  ),
                ),
              ),
              _DeleteButton(controller: controller, id: id, item: item),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountBox extends StatelessWidget {
  final int? value;

  const _CountBox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 84),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value != null ? '$value' : 'N/A',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'RESOURCES',
            style: TextStyle(
              color: AppColors.mint,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.mint.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.mint.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mint,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  final ManageNoOfResPerUserGetx controller;
  final int? id;
  final NoOfResoucesPerUserModel item;

  const _DeleteButton({
    required this.controller,
    required this.id,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool busy = id != null && controller.deletingId.value == id;
      final bool anyBusy = controller.deletingId.value != null;

      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: BorderSide(color: AppColors.danger.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        onPressed: (id == null || anyBusy)
            ? null
            : () => controller.confirmAndDelete(item),
        icon: busy
            ? const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.danger,
          ),
        )
            : const Icon(Icons.delete_outline_rounded, size: 18),
        label: Text(
          busy ? 'Deleting' : 'Delete',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );
    });
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: AppColors.danger, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.primaryText, fontSize: 15),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.body,
            ),
            onPressed: onRetry,
            child: const Text('Try again'),
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