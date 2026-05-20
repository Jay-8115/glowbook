import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Review } from '@workspace/api-client-react';
import { useColors } from '@/hooks/useColors';
import { RatingStars } from './RatingStars';

interface ReviewCardProps {
  review: Review;
}

export function ReviewCard({ review }: ReviewCardProps) {
  const colors = useColors();
  const date = new Date(review.createdAt).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });

  return (
    <View style={[styles.card, { backgroundColor: colors.card, borderRadius: colors.radius }]}>
      <View style={styles.header}>
        <Text style={[styles.name, { color: colors.cardForeground }]}>
          {review.user?.name || 'Anonymous'}
        </Text>
        <Text style={[styles.date, { color: colors.mutedForeground }]}>{date}</Text>
      </View>
      <View style={styles.ratingContainer}>
        <RatingStars rating={review.rating} size={14} />
      </View>
      {review.comment && (
        <Text style={[styles.comment, { color: colors.foreground }]} numberOfLines={4}>
          {review.comment}
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    padding: 16,
    marginBottom: 12,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  name: {
    fontSize: 14,
    fontFamily: 'Inter_600SemiBold',
  },
  date: {
    fontSize: 12,
    fontFamily: 'Inter_400Regular',
  },
  ratingContainer: {
    marginBottom: 12,
  },
  comment: {
    fontSize: 14,
    fontFamily: 'Inter_400Regular',
    lineHeight: 20,
  },
});