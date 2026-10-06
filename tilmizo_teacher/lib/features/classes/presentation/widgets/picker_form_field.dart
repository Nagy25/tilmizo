import 'package:core_package/core_package.dart';
import 'package:flutter/material.dart';

/// A tappable form field whose value comes from a picker dialog.
class PickerFormField<T> extends FormField<T> {
  PickerFormField({
    super.key,
    required String label,
    required String Function(T value) format,
    required Future<T?> Function(T? current) pick,
    required ValueChanged<T> onChanged,
    super.initialValue,
    super.validator,
    IconData icon = Icons.schedule,
    String? placeholder,
    super.enabled,
  }) : super(
         builder: (field) {
           final value = field.value;
           final enabled = field.widget.enabled;
           return TelmizoFormField(
             label: label,
             isRequired: true,
             child: InkWell(
               borderRadius: TelmizoRadius.mdAll,
               onTap: enabled
                   ? () async {
                       final picked = await pick(value);
                       if (picked == null) return;
                       field.didChange(picked);
                       onChanged(picked);
                     }
                   : null,
               child: InputDecorator(
                 isEmpty: value == null,
                 decoration: InputDecoration(
                   prefixIcon: Icon(icon),
                   hintText: placeholder,
                   errorText: field.errorText,
                   enabled: enabled,
                 ),
                 child: value == null ? null : Text(format(value)),
               ),
             ),
           );
         },
       );
}
