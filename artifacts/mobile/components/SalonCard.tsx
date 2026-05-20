import React from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { Image } from 'expo-image';
import { Feather } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';
import { RatingStars } from './RatingStars';
import { router } from 'expo-router';

interface SalonType {
  id: number;
  name: string;
  address: string;
  city: string;
  imageUrl?: string | null;
  avgRating: number;
  totalReviews: number;
  isActive: boolean;
  distanceKm?: number | null;
}

interface SalonCardProps {
  salon: SalonType;
  horizontal?: boolean;
}

export function SalonCard({ salon, horizontal = false }: SalonCardProps) {
  const colors = useColors();

  return (
    <Pressable
      onPress={() => router.push(`/salon/${salon.id}` as any)}
      style={[
        styles.card,
        {
          backgroundColor: colors.card,
          borderRadius: colors.radius,
          width: horizontal ? 280 : '100%',
        },
      ]}
    >
      <Image
        source={{
          uri:
            salon.imageUrl ||
            'https://images.unsplash.com/photo-1560066984-138dadb4c035?q=80&w=1074&auto=format&fit=crop',
        }}
        style={[
          styles.image,
          {
            borderTopLeftRadius: colors.radius,
            borderTopRightRadius: colors.radius,
          },
        ]}
        contentFit="cover"
      />
      <View style={styles.content}>
        <View style={styles.header}>
          <Text
            style={[styles.name, { color: colors.cardForeground }]}
            numberOfLines={1}
          >
            {salon.name}
          </Text>
          {salon.distanceKm != null && (
            <View style={styles.distanceBadge}>
              <Feather name="map-pin" size={12} color={colors.mutedForeground} />
              <Text style={[styles.distanceText, { color: colors.mutedForeground }]}>
                {salon.distanceKm.toFixed(1)} km
              </Text>
            </View>
          )}
        </View>

        <Text
          style={[styles.address, { color: colors.mutedForeground }]}
          numberOfLines={1}
        >
          {salon.address}, {salon.city}
        </Text>

        <View style={styles.footer}>
          <View style={styles.ratingContainer}>
            <RatingStars rating={salon.avgRating} size={14} />
            <Text style={[styles.reviewCount, { color: colors.mutedForeground }]}>
              ({salon.totalReviews})
            </Text>
          </View>
          <View
            style={[
              styles.statusIndicator,
              { backgroundColor: salon.isActive ? '#10b981' : '#ef4444' },
            ]}
          />
        </View>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  card: { overflow: 'hidden', marginBottom: 16 },
  image: { width: '100%', height: 160 },
  content: { padding: 16 },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 4,
  },
  name: { fontSize: 18, fontFamily: 'Inter_600SemiBold', flex: 1, marginRight: 8 },
  distanceBadge: { flexDirection: 'row', alignItems: 'center' },
  distanceText: { fontSize: 12, fontFamily: 'Inter_500Medium', marginLeft: 3 },
  address: { fontSize: 14, fontFamily: 'Inter_400Regular', marginBottom: 12 },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  ratingContainer: { flexDirection: 'row', alignItems: 'center' },
  reviewCount: { fontSize: 12, fontFamily: 'Inter_400Regular', marginLeft: 4 },
  statusIndicator: { width: 8, height: 8, borderRadius: 4 },
});
