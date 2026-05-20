import React from 'react';
import { Text, StyleSheet, Pressable } from 'react-native';
import { Feather } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';

const ICON_MAP: Record<string, keyof typeof Feather.glyphMap> = {
  scissors: 'scissors',
  sparkles: 'star',
  star: 'star',
  heart: 'heart',
  sun: 'sun',
  user: 'user',
  home: 'home',
  search: 'search',
  camera: 'camera',
  music: 'music',
};

function getFeatherIcon(name?: string): keyof typeof Feather.glyphMap {
  if (!name) return 'tag';
  return ICON_MAP[name] ?? 'tag';
}

interface CategoryChipProps {
  name: string;
  iconName?: string;
  selected?: boolean;
  onPress?: () => void;
}

export function CategoryChip({ name, iconName, selected, onPress }: CategoryChipProps) {
  const colors = useColors();
  const icon = getFeatherIcon(iconName);

  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.chip,
        {
          backgroundColor: selected ? colors.primary : colors.card,
          borderColor: selected ? colors.primary : colors.border,
          borderRadius: 20,
        },
      ]}
    >
      {iconName && (
        <Feather
          name={icon}
          size={14}
          color={selected ? colors.primaryForeground : colors.primary}
        />
      )}
      <Text
        style={[
          styles.text,
          { color: selected ? colors.primaryForeground : colors.foreground },
        ]}
      >
        {name}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderWidth: 1,
    gap: 6,
  },
  text: {
    fontSize: 13,
    fontFamily: 'Inter_500Medium',
  },
});
