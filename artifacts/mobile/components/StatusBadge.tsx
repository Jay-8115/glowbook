import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { BookingStatus } from '@workspace/api-client-react';

interface StatusBadgeProps {
  status: BookingStatus;
}

export function StatusBadge({ status }: StatusBadgeProps) {
  let backgroundColor = '#2A2A2A';
  let textColor = '#888888';
  let label = status.replace('_', ' ').toUpperCase();

  switch (status) {
    case 'pending':
      backgroundColor = '#452c00'; // dark amber
      textColor = '#f59e0b';
      break;
    case 'accepted':
      backgroundColor = '#0c2e4e'; // dark blue
      textColor = '#3b82f6';
      break;
    case 'in_progress':
      backgroundColor = '#38164f'; // dark purple
      textColor = '#a855f7';
      break;
    case 'completed':
      backgroundColor = '#06402b'; // dark green
      textColor = '#10b981';
      break;
    case 'cancelled':
      backgroundColor = '#4f0f0f'; // dark red
      textColor = '#ef4444';
      break;
  }

  return (
    <View style={[styles.badge, { backgroundColor, borderRadius: 16 }]}>
      <Text style={[styles.text, { color: textColor }]}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  badge: {
    paddingHorizontal: 8,
    paddingVertical: 4,
    alignSelf: 'flex-start',
  },
  text: {
    fontSize: 10,
    fontFamily: 'Inter_700Bold',
  },
});