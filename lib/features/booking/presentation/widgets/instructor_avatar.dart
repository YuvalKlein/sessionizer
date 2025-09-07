import 'package:flutter/material.dart';
import 'package:myapp/core/utils/injection_container.dart';
import 'package:myapp/features/user/domain/usecases/get_instructor_by_id.dart';
import 'package:myapp/features/user/domain/entities/user_profile_entity.dart';

class InstructorAvatar extends StatefulWidget {
  final String instructorId;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  const InstructorAvatar({
    super.key,
    required this.instructorId,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  State<InstructorAvatar> createState() => _InstructorAvatarState();
}

class _InstructorAvatarState extends State<InstructorAvatar> {
  UserProfileEntity? _instructor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstructor();
  }

  Future<void> _loadInstructor() async {
    try {
      final getInstructorById = sl<GetInstructorById>();
      final result = await getInstructorById(widget.instructorId);
      
      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        (instructor) {
          if (mounted) {
            setState(() {
              _instructor = instructor;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor ?? Colors.grey.shade300,
        child: SizedBox(
          width: widget.radius * 0.6,
          height: widget.radius * 0.6,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.iconColor ?? Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    if (_instructor == null) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: widget.backgroundColor ?? Colors.grey.shade300,
        child: Icon(
          Icons.person,
          size: widget.radius * 0.8,
          color: widget.iconColor ?? Colors.grey.shade600,
        ),
      );
    }

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor ?? Colors.grey.shade300,
      backgroundImage: _instructor!.photoUrl != null 
          ? NetworkImage(_instructor!.photoUrl!) 
          : null,
      child: _instructor!.photoUrl == null
          ? Icon(
              Icons.person,
              size: widget.radius * 0.8,
              color: widget.iconColor ?? Colors.grey.shade600,
            )
          : null,
    );
  }
}

class InstructorName extends StatefulWidget {
  final String instructorId;
  final TextStyle? style;

  const InstructorName({
    super.key,
    required this.instructorId,
    this.style,
  });

  @override
  State<InstructorName> createState() => _InstructorNameState();
}

class _InstructorNameState extends State<InstructorName> {
  UserProfileEntity? _instructor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstructor();
  }

  Future<void> _loadInstructor() async {
    try {
      final getInstructorById = sl<GetInstructorById>();
      final result = await getInstructorById(widget.instructorId);
      
      result.fold(
        (failure) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
        (instructor) {
          if (mounted) {
            setState(() {
              _instructor = instructor;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Text(
        'Loading...',
        style: widget.style ?? const TextStyle(color: Colors.grey),
      );
    }

    if (_instructor == null) {
      return Text(
        'Unknown Instructor',
        style: widget.style ?? const TextStyle(color: Colors.grey),
      );
    }

    return Text(
      _instructor!.displayName,
      style: widget.style,
    );
  }
}
