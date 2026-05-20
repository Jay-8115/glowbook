import React from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { Image } from 'expo-image';
import { StaffMember } from '@workspace/api-client-react';
import { useColors } from '@/hooks/useColors';

interface StaffChipProps {
  staff: StaffMember;
  onPress?: () => void;
  selected?: boolean;
}

export function StaffChip({ staff, onPress, selected }: StaffChipProps) {
  const colors = useColors();

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .map((n) => n[0])
      .join('')
      .toUpperCase()
      .substring(0, 2);
  };

  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.container,
        {
          backgroundColor: selected ? colors.secondary : 'transparent',
          borderColor: selected ? colors.primary : colors.border,
          borderRadius: colors.radius,
        },
      ]}
    >
      <View style={styles.avatarContainer}>
        {staff.avatarUrl ? (
          <Image source={{ uri: staff.avatarUrl }} style={styles.avatar} contentFit="cover" />
        ) : (
          <View style={[styles.avatarPlaceholder, { backgroundColor: colors.muted }]}>
            <Text style={[styles.initials, { color: colors.foreground }]}>{getInitials(staff.name)}</Text>
          </View>
        )}
        <View
          style={[
            styles.statusDot,
            { backgroundColor: staff.isAvailable ? '#10b981' : '#ef4444', borderColor: colors.background },
          ]}
        />
      </View>
      <Text style={[styles.name, { color: colors.foreground }]} numberOfLines={1}>
        {staff.name}
      </Text>
      {staff.role && (
        <Text style={[styles.role, { color: colors.mutedForeground }]} numberOfLines={1}>
          {staff.role}
        </Text>
      )}
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
    padding: 12,
    borderWidth: 1,
    width: 100,
  },
  avatarContainer: {
    position: 'relative',
    marginBottom: 8,
  },
  avatar: {
    width: 56,
    height: 56,
    borderRadius: 28,
  },
  avatarPlaceholder: {
    width: 56,
    height: 56,
    borderRadius: 28,
    alignItems: 'center',
    justifyContent: 'center',
  },
  initials: {
    fontSize: 18,
    fontFamily: 'Inter_600SemiBold',
  },
  statusDot: {
    position: 'absolute',
    bottom: 2,
    right: 2,
    width: 14,
    height: 14,
    borderRadius: 7,
    borderWidth: 2,
  },
  name: {
    fontSize: 14,
    fontFamily: 'Inter_500Medium',
    textAlign: 'center',
  },
  role: {
    fontSize: 12,
    fontFamily: 'Inter_400Regular',
    textAlign: 'center',
    marginTop: 2,
  },
});