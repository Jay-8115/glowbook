import React, { useEffect, useRef } from 'react';
import { Animated, Platform, StyleSheet, ViewStyle } from 'react-native';

import { useColors } from '@/hooks/useColors';

interface LoadingSkeletonProps {
  style?: ViewStyle;
  width?: number | string;
  height?: number | string;
  borderRadius?: number;
}

export function LoadingSkeleton({ style, width, height, borderRadius }: LoadingSkeletonProps) {
  const colors = useColors();
  const animatedValue = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    const nativeDriver = Platform.OS !== 'web';
    const animation = Animated.loop(
      Animated.sequence([
        Animated.timing(animatedValue, { toValue: 1, duration: 1000, useNativeDriver: nativeDriver }),
        Animated.timing(animatedValue, { toValue: 0, duration: 1000, useNativeDriver: nativeDriver }),
      ]),
    );
    animation.start();
    return () => animation.stop();
  }, [animatedValue]);

  const opacity = animatedValue.interpolate({
    inputRange: [0, 1],
    outputRange: [0.3, 0.7],
  });

  return (
    <Animated.View
      style={[
        styles.skeleton,
        {
          backgroundColor: colors.muted,
          opacity,
          width,
          height,
          borderRadius: borderRadius ?? colors.radius,
        },
        style,
      ]}
    />
  );
}

const styles = StyleSheet.create({
  skeleton: {
    overflow: 'hidden',
  },
});