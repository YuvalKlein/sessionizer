import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:myapp/features/review/presentation/bloc/review_bloc.dart';
import 'package:myapp/features/review/presentation/bloc/review_event.dart';
import 'package:myapp/features/review/presentation/bloc/review_state.dart';

class ReviewDialog extends StatefulWidget {
  final String bookingId;
  final String clientId;
  final String instructorId;
  final String sessionId;
  final String? existingReviewId;
  final int? existingRating;
  final String? existingComment;

  const ReviewDialog({
    Key? key,
    required this.bookingId,
    required this.clientId,
    required this.instructorId,
    required this.sessionId,
    this.existingReviewId,
    this.existingRating,
    this.existingComment,
  }) : super(key: key);

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRating != null) {
      _rating = widget.existingRating!;
    }
    if (widget.existingComment != null) {
      _commentController.text = widget.existingComment!;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReviewBloc, ReviewState>(
      listener: (context, state) {
        if (state is ReviewCreated) {
          Navigator.of(context).pop(true); // Return true to indicate success
        } else if (state is ReviewError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
        }
      },
      child: AlertDialog(
        title: Text(widget.existingReviewId != null ? 'Edit Review' : 'Leave a Review'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How was your session?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Comment field
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Comments (optional)',
                  hintText: 'Tell us about your experience...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                maxLength: 500,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(widget.existingReviewId != null ? 'Update' : 'Submit'),
          ),
        ],
      ),
    );
  }

  void _submitReview() {
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    context.read<ReviewBloc>().add(CreateReviewEvent(
      bookingId: widget.bookingId,
      clientId: widget.clientId,
      instructorId: widget.instructorId,
      sessionId: widget.sessionId,
      rating: _rating,
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    ));
  }
}
