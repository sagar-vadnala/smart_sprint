import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_sprint/features/workspace/model/team_member.dart';

class MemberAvatar extends StatelessWidget {
  final TeamMember member;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  const MemberAvatar({
    super.key,
    required this.member,
    this.size = 28,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: member.avatarColor,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        member.initials,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Overlapping row of avatars with a "+N" overflow chip.
class AvatarStack extends StatelessWidget {
  final List<TeamMember> members;
  final double size;
  final double overlap;
  final int max;
  final Color borderColor;

  const AvatarStack({
    super.key,
    required this.members,
    required this.borderColor,
    this.size = 26,
    this.overlap = 9,
    this.max = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Icon(
            Icons.person_outline_rounded,
            size: size * 0.5,
            color: borderColor,
          ),
        ),
      );
    }

    final shown = members.take(max).toList();
    final overflow = members.length - shown.length;
    final step = size - overlap;
    final count = shown.length + (overflow > 0 ? 1 : 0);
    final width = size + step * (count - 1);

    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: MemberAvatar(
                member: shown[i],
                size: size,
                borderColor: borderColor,
                borderWidth: 2,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * step,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$overflow',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
