import React from 'react';
import { View, StyleSheet } from 'react-native';
import { FontAwesome } from '@expo/vector-icons';
import { useColors } from '@/hooks/useColors';

interface RatingStarsProps {
  rating: number;
  size?: number;
  maxStars?: number;
}

export function RatingStars({ rating, size = 16, maxStars = 5 }: RatingStarsProps) {
  const colors = useColors();
  
  return (
    <View style={styles.container}>
      {[...Array(maxStars)].map((_, i) => {
        const starValue = i + 1;
        const isFullStar = rating >= starValue;
        const isHalfStar = rating >= starValue - 0.5 && rating < starValue;
        
        let iconName: 'star' | 'star-half-empty' | 'star-o' = 'star-o';
        if (isFullStar) {
          iconName = 'star';
        } else if (isHalfStar) {
          iconName = 'star-half-empty';
        }

        return (
          <FontAwesome
            key={i}
            name={iconName}
            size={size}
            color={isFullStar || isHalfStar ? colors.primary : colors.muted}
          />
        );
      })}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 2,
  },
});