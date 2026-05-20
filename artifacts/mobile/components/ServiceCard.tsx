import React from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { Service } from '@workspace/api-client-react';
import { useColors } from '@/hooks/useColors';

interface ServiceCardProps {
  service: Service;
  onPress?: () => void;
  selected?: boolean;
}

export function ServiceCard({ service, onPress, selected }: ServiceCardProps) {
  const colors = useColors();

  return (
    <Pressable
      onPress={onPress}
      style={[
        styles.card,
        {
          backgroundColor: colors.card,
          borderColor: selected ? colors.primary : colors.border,
          borderRadius: colors.radius,
        },
      ]}
    >
      <View style={styles.content}>
        <View style={styles.header}>
          <Text style={[styles.name, { color: colors.cardForeground }]}>{service.name}</Text>
          <Text style={[styles.price, { color: colors.primary }]}>${service.price.toFixed(2)}</Text>
        </View>
        {service.description && (
          <Text style={[styles.description, { color: colors.mutedForeground }]} numberOfLines={2}>
            {service.description}
          </Text>
        )}
        <View style={styles.footer}>
          <Text style={[styles.duration, { color: colors.mutedForeground }]}>
            {service.durationMinutes} min
          </Text>
          {service.category && (
            <Text style={[styles.category, { color: colors.mutedForeground }]}>
              • {service.category}
            </Text>
          )}
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: {
    borderWidth: 1,
    padding: 16,
  },
  content: {
    gap: 6,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    gap: 16,
  },
  name: {
    fontSize: 16,
    fontFamily: 'Inter_600SemiBold',
    flex: 1,
  },
  price: {
    fontSize: 16,
    fontFamily: 'Inter_700Bold',
  },
  description: {
    fontSize: 14,
    fontFamily: 'Inter_400Regular',
  },
  footer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  duration: {
    fontSize: 12,
    fontFamily: 'Inter_500Medium',
  },
  category: {
    fontSize: 12,
    fontFamily: 'Inter_500Medium',
  },
});