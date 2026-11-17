// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringRuleAdapter extends TypeAdapter<RecurringRule> {
  @override
  final int typeId = 4;

  @override
  RecurringRule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringRule(
      type: fields[0] as int,
      amount: fields[1] as int,
      categoryId: fields[2] as int?,
      note: fields[3] as String?,
      currency: fields[4] as String,
      frequency: fields[5] as int,
      dayValue: fields[6] as int,
      startDate: fields[7] as String,
      active: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringRule obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.note)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.frequency)
      ..writeByte(6)
      ..write(obj.dayValue)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.active);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRuleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
