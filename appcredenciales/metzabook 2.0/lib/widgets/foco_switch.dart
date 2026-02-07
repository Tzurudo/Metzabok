import 'package:flutter/material.dart';

<<<<<<< HEAD
class FocoSwitch extends StatelessWidget {
=======
class FocoSwitch extends StatefulWidget {
>>>>>>> 5c92128 (Initial commit)
  final String titulo;
  final bool estado;
  final bool loading;
  final bool enabled;
  final Function(bool) onChanged;
  final FocusNode? focusNode;

  const FocoSwitch({
    super.key,
    required this.titulo,
    required this.estado,
    this.loading = false,
    this.enabled = true,
    required this.onChanged,
    this.focusNode,
  });

  @override
<<<<<<< HEAD
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          title: Text(
            titulo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: enabled ? Colors.black87 : Colors.grey[400],
            ),
          ),
          trailing: loading
              ? const SizedBox(
                  width: 36,
                  height: 24,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : Switch(
                  value: estado,
                  onChanged: enabled ? onChanged : null,
                  activeColor: const Color(0xFFD4AF37),
                ),
        ),
=======
  State<FocoSwitch> createState() => _FocoSwitchState();
}

class _FocoSwitchState extends State<FocoSwitch> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _colorAnimation =
        ColorTween(
          begin: _getBackgroundColor(),
          end: _getBackgroundColor(),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );

    if (widget.estado) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(FocoSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estado != oldWidget.estado) {
      if (widget.estado) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  Color _getBackgroundColor() {
    return widget.estado ? Colors.green[50]! : Colors.grey[100]!;
  }

  Color _getSwitchColor() {
    return widget.estado ? Colors.green : Colors.grey;
  }

  Color _getTitleColor() {
    return widget.estado ? Colors.green[800]! : Colors.black87;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      child: AnimatedBuilder(
        animation: _colorAnimation,
        builder: (context, child) {
          return Card(
            elevation: widget.estado ? 6 : 2,
            color: _getBackgroundColor(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: widget.estado ? Colors.green : Colors.grey[300]!,
                width: widget.estado ? 2 : 1,
              ),
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                widget.titulo,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled ? _getTitleColor() : Colors.grey[400],
                  letterSpacing: 0.3,
                ),
              ),
              trailing: widget.loading
                  ? SizedBox(
                      width: 36,
                      height: 24,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getSwitchColor(),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Transform.scale(
                      scale: widget.estado ? 1.1 : 1.0,
                      child: Switch(
                        value: widget.estado,
                        onChanged: widget.enabled ? widget.onChanged : null,
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey[300],
                      ),
                    ),
              onTap: !widget.enabled || widget.loading
                  ? null
                  : () => widget.onChanged(!widget.estado),
            ),
          );
        },
>>>>>>> 5c92128 (Initial commit)
      ),
    );
  }
}
