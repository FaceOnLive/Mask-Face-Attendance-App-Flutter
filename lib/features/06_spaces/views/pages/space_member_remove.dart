import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/models/member.dart';
import '../../../../core/models/space.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/member_image_leading.dart';
import '../../../03_attendance/views/components/components.dart';
import '../../../05_members/views/controllers/member_controller.dart';
import '../controllers/space_controller.dart';

class SpaceMemberRemoveScreen extends StatefulWidget {
  const SpaceMemberRemoveScreen({super.key, required this.space});

  final Space space;

  @override
  _SpaceMemberRemoveScreenState createState() =>
      _SpaceMemberRemoveScreenState();
}

class _SpaceMemberRemoveScreenState extends State<SpaceMemberRemoveScreen> {
  /* <---- Dependency -----> */
  final MembersController _membersController = Get.find();
  final SpaceController _spaceController = Get.find();

  /* <---- Selection -----> */
  final List<Member> _availableMemberInSpace = [];
  final RxList<Member> _selectedMember = RxList<Member>();

  void _onMemberSelect(Member member) {
    if (_selectedMember.contains(member)) {
      _selectedMember.remove(member);
    } else {
      _selectedMember.add(member);
    }
    _membersController.update();
  }

  /// Progress BOOL
  final RxBool _isRemovingMember = false.obs;

  /// Remove Member From Available List
  void _filterOutAddedMember() {
    List<Member> allMember = Get.find<MembersController>().allMembers;
    List<String> allMemberIDs = [];
    for (Member singleMember in allMember) {
      allMemberIDs.add(singleMember.memberID!);
    }

    for (var element in allMember) {
      if (widget.space.memberList.contains(element.memberID) ||
          widget.space.appMembers.contains(element.memberID!)) {
        _availableMemberInSpace.add(element);
      } else {
        // That means the member is already in their list
      }
    }
    _membersController.update();
  }

  @override
  void initState() {
    super.initState();
    _filterOutAddedMember();
  }

  @override
  void dispose() {
    _isRemovingMember.close();
    _selectedMember.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remove Members'),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: context.theme.scaffoldBackgroundColor,
        ),
        child: SafeArea(
          child: Column(
            children: [
              /* <---- List -----> */
              GetBuilder<MembersController>(
                builder: (controller) => controller.isFetchingUser
                    ? const LoadingMembers()
                    : _availableMemberInSpace.isNotEmpty
                        ? Expanded(
                            child: ListView.builder(
                              itemCount: _availableMemberInSpace.length,
                              itemBuilder: (context, index) {
                                Member currentMember =
                                    _availableMemberInSpace[index];
                                return _MemberListTile(
                                  member: currentMember,
                                  isSelected:
                                      _selectedMember.contains(currentMember),
                                  onTap: () {
                                    _onMemberSelect(currentMember);
                                  },
                                );
                              },
                            ),
                          )
                        : const _EmptyMemberList(),
              ),
              /* <---- Add Button -----> */
              Obx(() => AppButton(
                    disableBorderRadius: true,
                    margin: const EdgeInsets.all(0),
                    padding: const EdgeInsets.all(AppDefaults.padding),
                    label: 'Remove',
                    isLoading: _isRemovingMember.value,
                    backgroundColor: AppColors.appRed,
                    isButtonDisabled: _selectedMember.isEmpty,
                    onTap: () async {
                      try {
                        _isRemovingMember.trigger(true);
                        await _spaceController.removeMembersFromSpace(
                          spaceID: widget.space.spaceID!,
                          members: _selectedMember,
                        );
                        Get.back();
                        Get.back();
                        Get.back(closeOverlays: false);
                        Get.rawSnackbar(
                          title: 'Member Removed Successfully',
                          message:
                              'Total ${_selectedMember.length} Members has been removed',
                          backgroundColor: AppColors.appRed,
                          snackStyle: SnackStyle.GROUNDED,
                        );
                        _isRemovingMember.trigger(false);
                      } on FirebaseException catch (e) {
                        print(e);
                        _isRemovingMember.trigger(false);
                      }
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMemberList extends StatelessWidget {
  const _EmptyMemberList();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: Get.width * 0.6,
            child: Image.asset(AppImages.illustrationMemberEmpty),
          ),
          AppSizes.hGap20,
          const Text('There is no one to remove'),
        ],
      ),
    );
  }
}

class _MemberListTile extends StatelessWidget {
  const _MemberListTile({
    required this.member,
    required this.onTap,
    this.isSelected = false,
  });

  final Member member;
  final bool isSelected;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Hero(
        tag: member.memberID ?? member.memberNumber,
        child: MemberImageLeading(
          imageLink: member.memberPicture,
        ),
      ),
      title: Text(member.memberName),
      subtitle: Text(member.memberNumber.toString()),
      trailing: Checkbox(
        onChanged: (v) {
          onTap();
        },
        value: isSelected,
      ),
    );
  }
}
